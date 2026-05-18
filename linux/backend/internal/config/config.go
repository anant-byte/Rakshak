package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	ListenAddr         string
	SecretKey          string
	DBDriver           string
	DBDSN              string
	DataDir            string
	BlocklistDir       string
	BlockIP            string
	BlockIPv6          string
	Upstream           string
	LogLevel           string
	QueryRetentionDays int
	CORSOrigins        []string
	AdminEmail         string
	AdminPassword      string
	LanIP              string
	ForceDNS           bool
	InternalSecret     string
}

func Load() (*Config, error) {
	c := &Config{
		ListenAddr:         env("RAKSHAK_LISTEN", ":8080"),
		SecretKey:          env("RAKSHAK_SECRET_KEY", ""),
		DBDriver:           env("RAKSHAK_DB_DRIVER", "sqlite"),
		DBDSN:              env("RAKSHAK_DB_DSN", "file:/data/rakshak.db?cache=shared&_journal_mode=WAL"),
		DataDir:            env("RAKSHAK_DATA_DIR", "./data"),
		BlocklistDir:       env("RAKSHAK_BLOCKLIST_DIR", "./blocklists"),
		BlockIP:            env("RAKSHAK_DNS_BLOCK_IP", "0.0.0.0"),
		BlockIPv6:          env("RAKSHAK_DNS_BLOCK_IPV6", "::"),
		Upstream:           env("RAKSHAK_UPSTREAM", "127.0.0.1:5353"),
		LogLevel:           env("RAKSHAK_LOG_LEVEL", "info"),
		QueryRetentionDays: envInt("RAKSHAK_QUERY_LOG_RETENTION_DAYS", 7),
		CORSOrigins:        strings.Split(env("RAKSHAK_CORS_ORIGINS", "http://localhost:3000"), ","),
		AdminEmail:         env("RAKSHAK_ADMIN_EMAIL", "admin@rakshak.lan"),
		AdminPassword:      env("RAKSHAK_ADMIN_PASSWORD", ""),
		LanIP:              env("RAKSHAK_LAN_IP", ""),
		ForceDNS:           envBool("RAKSHAK_FORCE_DNS", false),
		InternalSecret:     env("RAKSHAK_INTERNAL_SECRET", ""),
	}
	if c.SecretKey == "" {
		return nil, fmt.Errorf("RAKSHAK_SECRET_KEY is required (min 32 bytes)")
	}
	if len(c.SecretKey) < 32 {
		return nil, fmt.Errorf("RAKSHAK_SECRET_KEY must be at least 32 characters")
	}
	if c.InternalSecret == "" {
		return nil, fmt.Errorf("RAKSHAK_INTERNAL_SECRET is required (min 16 characters)")
	}
	if len(c.InternalSecret) < 16 {
		return nil, fmt.Errorf("RAKSHAK_INTERNAL_SECRET must be at least 16 characters")
	}
	return c, nil
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func envInt(k string, def int) int {
	if v := os.Getenv(k); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func envBool(k string, def bool) bool {
	if v := os.Getenv(k); v != "" {
		return v == "1" || strings.EqualFold(v, "true") || v == "yes"
	}
	return def
}
