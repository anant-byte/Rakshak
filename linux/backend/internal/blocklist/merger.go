package blocklist

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/models"
	"gorm.io/gorm"
)

var domainRe = regexp.MustCompile(`^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$`)

type Merger struct {
	cfg *config.Config
	db  *gorm.DB
}

func NewMerger(cfg *config.Config, db *gorm.DB) *Merger {
	return &Merger{cfg: cfg, db: db}
}

func (m *Merger) UpdateAll() (int, string, error) {
	if err := os.MkdirAll(m.cfg.BlocklistDir, 0755); err != nil {
		return 0, "", err
	}

	var feeds []models.BlocklistFeed
	if err := m.db.Where("enabled = ?", true).Find(&feeds).Error; err != nil {
		return 0, "", err
	}

	policies, err := m.loadPolicyFilters()
	if err != nil {
		return 0, "", err
	}

	domains := make(map[string]struct{})
	allow := make(map[string]struct{})

	for _, line := range strings.Split(policies.globalAllow, "\n") {
		line = normalizeDomain(line)
		if line != "" {
			allow[line] = struct{}{}
		}
	}

	client := &http.Client{Timeout: 120 * time.Second}

	for _, feed := range feeds {
		if !m.categoryEnabled(feed.Category, policies) {
			continue
		}
		count, err := m.fetchFeed(client, feed, domains)
		status := "ok"
		if err != nil {
			status = err.Error()
		}
		m.db.Model(&feed).Updates(map[string]interface{}{
			"last_updated": time.Now(),
			"last_status":  status,
			"entry_count":  count,
		})
	}

	// Per-policy custom blocklists merged into global for CoreDNS hosts file
	for _, bl := range policies.customBlocks {
		for _, line := range strings.Split(bl, "\n") {
			d := normalizeDomain(line)
			if d != "" {
				domains[d] = struct{}{}
			}
		}
	}

	// Remove allowlisted
	for a := range allow {
		delete(domains, a)
	}

	sorted := make([]string, 0, len(domains))
	for d := range domains {
		sorted = append(sorted, d)
	}
	sort.Strings(sorted)

	outPath := filepath.Join(m.cfg.BlocklistDir, "blocked.hosts")
	if err := m.writeHostsFile(outPath, sorted); err != nil {
		return 0, "", err
	}

	sum := sha256.Sum256([]byte(strings.Join(sorted, "\n")))
	checksum := hex.EncodeToString(sum[:8])
	version := time.Now().UTC().Format("20060102-150405")

	m.db.Create(&models.BlocklistVersion{
		Version:      version,
		AppliedAt:    time.Now(),
		TotalDomains: len(sorted),
		Checksum:     checksum,
	})

	return len(sorted), version, nil
}

type policyFilters struct {
	globalAllow  string
	customBlocks []string
	blockAds     bool
	blockMalware bool
	blockPhishing bool
	blockScam    bool
	blockTelemetry bool
	blockMiners  bool
	blockTrackers bool
	blockExploits bool
}

func (m *Merger) loadPolicyFilters() (*policyFilters, error) {
	var defaultPolicy models.Policy
	if err := m.db.Where("name = ?", "default").First(&defaultPolicy).Error; err != nil {
		return &policyFilters{
			blockAds: true, blockMalware: true, blockPhishing: true,
			blockScam: true, blockTelemetry: true, blockMiners: true,
			blockTrackers: true, blockExploits: true,
		}, nil
	}
	return &policyFilters{
		globalAllow:    defaultPolicy.CustomAllowlist,
		customBlocks:   []string{defaultPolicy.CustomBlocklist},
		blockAds:       defaultPolicy.BlockAds,
		blockMalware:   defaultPolicy.BlockMalware,
		blockPhishing:  defaultPolicy.BlockPhishing,
		blockScam:      defaultPolicy.BlockScam,
		blockTelemetry: defaultPolicy.BlockTelemetry,
		blockMiners:    defaultPolicy.BlockMiners,
		blockTrackers:  defaultPolicy.BlockTrackers,
		blockExploits:  defaultPolicy.BlockExploits,
	}, nil
}

func (m *Merger) categoryEnabled(cat string, p *policyFilters) bool {
	switch cat {
	case "ads":
		return p.blockAds || p.blockTrackers
	case "trackers":
		return p.blockTrackers
	case "malware":
		return p.blockMalware || p.blockExploits
	case "phishing":
		return p.blockPhishing
	case "scam":
		return p.blockScam
	case "telemetry":
		return p.blockTelemetry
	case "miners":
		return p.blockMiners
	default:
		return true
	}
}

func (m *Merger) fetchFeed(client *http.Client, feed models.BlocklistFeed, domains map[string]struct{}) (int, error) {
	req, err := http.NewRequest(http.MethodGet, feed.URL, nil)
	if err != nil {
		return 0, err
	}
	req.Header.Set("User-Agent", "RAKSHAK/1.0 blocklist-updater")

	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	tmp, err := os.CreateTemp(m.cfg.BlocklistDir, "feed-*.txt")
	if err != nil {
		return 0, err
	}
	defer os.Remove(tmp.Name())

	if _, err := io.Copy(tmp, resp.Body); err != nil {
		tmp.Close()
		return 0, err
	}
	tmp.Close()

	f, err := os.Open(tmp.Name())
	if err != nil {
		return 0, err
	}
	defer f.Close()

	count := 0
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		for _, d := range parseLine(sc.Text()) {
			if _, ok := domains[d]; !ok {
				domains[d] = struct{}{}
				count++
			}
		}
	}
	return count, sc.Err()
}

func parseLine(line string) []string {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, "#") {
		return nil
	}
	// hosts format: 0.0.0.0 domain.com
	fields := strings.Fields(line)
	var candidate string
	switch len(fields) {
	case 1:
		candidate = fields[0]
	case 2, 3:
		if fields[0][0] >= '0' && fields[0][0] <= '9' {
			candidate = fields[1]
		} else {
			candidate = fields[0]
		}
	default:
		candidate = fields[len(fields)-1]
	}
	candidate = normalizeDomain(candidate)
	if candidate == "" || !domainRe.MatchString(candidate) {
		return nil
	}
	// wildcard roots: *.example.com -> example.com sinkhole still matches subdomains in CoreDNS hosts
	if strings.HasPrefix(candidate, "*.") {
		candidate = candidate[2:]
	}
	return []string{candidate}
}

func normalizeDomain(s string) string {
	s = strings.TrimSpace(strings.ToLower(s))
	s = strings.TrimPrefix(s, "http://")
	s = strings.TrimPrefix(s, "https://")
	if i := strings.Index(s, "/"); i > 0 {
		s = s[:i]
	}
	if i := strings.Index(s, ":"); i > 0 {
		s = s[:i]
	}
	return s
}

func (m *Merger) writeHostsFile(path string, domains []string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	fmt.Fprintf(w, "# RAKSHAK generated %s\n", time.Now().UTC().Format(time.RFC3339))
	fmt.Fprintf(w, "# Domains: %d\n", len(domains))
	blockIP := m.cfg.BlockIP
	for _, d := range domains {
		fmt.Fprintf(w, "%s %s\n", blockIP, d)
	}
	return w.Flush()
}
