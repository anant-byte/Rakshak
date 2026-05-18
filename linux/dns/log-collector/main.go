// RAKSHAK log collector — parses CoreDNS combined logs, batches to API
package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

// [INFO] 192.168.1.42:53123 - 59183 "A IN doubleclick.net. udp 41 false 512" NOERROR - 0 2.000091ms
var logLineRe = regexp.MustCompile(`\[INFO\]\s+(\S+?)(?::\d+)?\s+-\s+\d+\s+"(\w+)\s+IN\s+([^"]+)"`)

func main() {
	apiURL := env("RAKSHAK_API_URL", "http://rakshak-api:8080/api/v1/internal/query-log")
	secret := env("RAKSHAK_INTERNAL_SECRET", "")
	logPath := env("RAKSHAK_LOG_PATH", "") // empty = stdin (pipe from docker logs)

	var scanner *bufio.Scanner
	if logPath != "" {
		f, err := os.Open(logPath)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		scanner = bufio.NewScanner(f)
	} else {
		scanner = bufio.NewScanner(os.Stdin)
	}

	client := &http.Client{Timeout: 5 * time.Second}
	batch := make([]map[string]string, 0, 50)
	ticker := time.NewTicker(2 * time.Second)
	done := make(chan struct{})

	go func() {
		for range ticker.C {
			if len(batch) > 0 {
				flush(client, apiURL, secret, batch)
				batch = batch[:0]
			}
		}
	}()

	for scanner.Scan() {
		line := scanner.Text()
		m := logLineRe.FindStringSubmatch(line)
		if len(m) < 4 {
			continue
		}
		clientIP := strings.Split(m[1], ":")[0]
		domain := strings.TrimSuffix(strings.Fields(m[3])[0], ".")
		action := "allowed"
		if strings.Contains(line, "NXDOMAIN") || strings.Contains(line, "REFUSED") {
			action = "blocked"
		}
		// Sinkhole often returns NOERROR with 0.0.0.0 — detect via plugin metadata not in log;
		// blocked.hosts hits still show NOERROR; mark domains matching known block patterns in v1.1
		if strings.Contains(domain, "ads.") || strings.Contains(domain, "tracker.") {
			action = "blocked"
		}
		batch = append(batch, map[string]string{
			"client_ip":  clientIP,
			"domain":     domain,
			"query_type": m[2],
			"action":     action,
			"category":   "",
		})
		if len(batch) >= 50 {
			flush(client, apiURL, secret, batch)
			batch = batch[:0]
		}
	}
	close(done)
	if len(batch) > 0 {
		flush(client, apiURL, secret, batch)
	}
}

func flush(client *http.Client, apiURL, secret string, batch []map[string]string) {
	for _, item := range batch {
		body, _ := json.Marshal(item)
		req, err := http.NewRequest(http.MethodPost, apiURL, bytes.NewReader(body))
		if err != nil {
			continue
		}
		req.Header.Set("Content-Type", "application/json")
		if secret != "" {
			req.Header.Set("X-Rakshak-Internal", secret)
		}
		resp, err := client.Do(req)
		if err != nil {
			log.Printf("ingest %s: %v", item["domain"], err)
			continue
		}
		resp.Body.Close()
	}
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
