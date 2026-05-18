package worker

import (
	"log"
	"os"
	"path/filepath"

	"github.com/rakshak/rakshak/internal/blocklist"
	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/db"
	"github.com/rakshak/rakshak/internal/discovery"
	"github.com/robfig/cron/v3"
)

func Run(cfg *config.Config) error {
	database, err := db.Open(cfg)
	if err != nil {
		return err
	}
	if err := db.Seed(cfg, database); err != nil {
		return err
	}

	merger := blocklist.NewMerger(cfg, database)

	c := cron.New()
	// Daily blocklist update at 04:00
	c.AddFunc("0 4 * * *", func() {
		n, ver, err := merger.UpdateAll()
		if err != nil {
			log.Printf("blocklist update failed: %v", err)
			return
		}
		log.Printf("blocklist updated: %d domains, %s", n, ver)
		signalCoreDNSReload(cfg)
	})

	// Device discovery every 15 minutes
	c.AddFunc("*/15 * * * *", func() {
		if _, err := os.Stat("/proc/net/arp"); err == nil {
			n, err := discovery.ScanARPTable(database)
			if err != nil {
				log.Printf("discovery failed: %v", err)
			} else if n > 0 {
				log.Printf("discovered/updated %d devices", n)
			}
		}
	})

	// Query log retention daily
	c.AddFunc("30 3 * * *", func() {
		if err := db.PurgeOldQueryLogs(database, cfg.QueryRetentionDays); err != nil {
			log.Printf("purge logs: %v", err)
		}
	})

	c.Start()
	log.Println("RAKSHAK worker started")
	select {}
}

func signalCoreDNSReload(cfg *config.Config) {
	// Touch reload marker — CoreDNS file plugin reloads on SIGHUP via sidecar script
	marker := filepath.Join(cfg.BlocklistDir, ".reload")
	_ = os.WriteFile(marker, []byte("1"), 0644)
}
