package db

import (
	"fmt"
	"time"

	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Open(cfg *config.Config) (*gorm.DB, error) {
	var dialector gorm.Dialector
	switch cfg.DBDriver {
	case "postgres":
		dialector = postgres.Open(cfg.DBDSN)
	default:
		dialector = sqlite.Open(cfg.DBDSN)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, err
	}

	if err := db.AutoMigrate(
		&models.User{},
		&models.Device{},
		&models.DeviceGroup{},
		&models.Policy{},
		&models.DNSQueryLog{},
		&models.BlocklistFeed{},
		&models.BlocklistVersion{},
		&models.SystemSetting{},
		&models.AuditLog{},
	); err != nil {
		return nil, err
	}

	return db, nil
}

func Seed(cfg *config.Config, db *gorm.DB) error {
	var count int64
	db.Model(&models.User{}).Count(&count)
	if count == 0 && cfg.AdminPassword != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(cfg.AdminPassword), bcrypt.DefaultCost)
		if err != nil {
			return err
		}
		db.Create(&models.User{
			Email:        cfg.AdminEmail,
			PasswordHash: string(hash),
			Role:         "admin",
		})
	}

	var policyCount int64
	db.Model(&models.Policy{}).Count(&policyCount)
	if policyCount == 0 {
		defaultPolicy := models.Policy{
			Name:            "default",
			BlockAds:        true,
			BlockTrackers:   true,
			BlockMalware:    true,
			BlockPhishing:   true,
			BlockScam:       true,
			BlockTelemetry:  true,
			BlockMiners:     true,
			BlockExploits:   true,
		}
		db.Create(&defaultPolicy)

		db.Create(&models.DeviceGroup{
			Name:        "default",
			Description: "All devices",
			PolicyID:    defaultPolicy.ID,
		})
	}

	return seedFeeds(db)
}

func seedFeeds(db *gorm.DB) error {
	feeds := []models.BlocklistFeed{
		{Name: "oisd-big", URL: "https://big.oisd.nl/domainswild", Category: "ads", Enabled: true},
		{Name: "stevenblack", URL: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", Category: "ads", Enabled: true},
		{Name: "phishing-army", URL: "https://phishing.army/download/phishing_army_blocklist_extended.txt", Category: "phishing", Enabled: true},
		{Name: "urlhaus", URL: "https://urlhaus.abuse.ch/downloads/hostfile/", Category: "malware", Enabled: true},
		{Name: "hagezi-malware", URL: "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/multi.txt", Category: "malware", Enabled: true},
		{Name: "hagezi-telemetry", URL: "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/tif.txt", Category: "telemetry", Enabled: true},
		{Name: "nocoin", URL: "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt", Category: "miners", Enabled: true},
		{Name: "scam-blocklist", URL: "https://raw.githubusercontent.com/durablenapkin/scamblocklist/main/hosts.txt", Category: "scam", Enabled: true},
		{Name: "hagezi-fraud", URL: "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/fake.txt", Category: "scam", Enabled: true},
		{Name: "urlhaus-domains", URL: "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-domains.txt", Category: "malware", Enabled: true},
		{Name: "phishing-filter", URL: "https://malware-filter.gitlab.io/malware-filter/phishing-filter.txt", Category: "phishing", Enabled: true},
		{Name: "rpilist-malware", URL: "https://raw.githubusercontent.com/RPiList/specials/master/Blocklists/malware", Category: "malware", Enabled: true},
		{Name: "spam404", URL: "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt", Category: "scam", Enabled: true},
		{Name: "hagezi-popup", URL: "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/popupads.txt", Category: "ads", Enabled: true},
	}

	for _, f := range feeds {
		var existing models.BlocklistFeed
		if err := db.Where("name = ?", f.Name).First(&existing).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&f)
			}
		}
	}
	return nil
}

func PurgeOldQueryLogs(db *gorm.DB, retentionDays int) error {
	cutoff := time.Now().AddDate(0, 0, -retentionDays)
	return db.Where("timestamp < ?", cutoff).Delete(&models.DNSQueryLog{}).Error
}

func DSNForSQLite(path string) string {
	return fmt.Sprintf("file:%s?cache=shared&_journal_mode=WAL", path)
}
