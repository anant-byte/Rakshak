package discovery

import (
	"bufio"
	"net"
	"os"
	"strings"
	"time"

	"github.com/rakshak/rakshak/internal/models"
	"gorm.io/gorm"
)

// ScanARPTable reads /proc/net/arp (Linux) and upserts devices.
func ScanARPTable(db *gorm.DB) (int, error) {
	f, err := os.Open("/proc/net/arp")
	if err != nil {
		return 0, err
	}
	defer f.Close()

	updated := 0
	sc := bufio.NewScanner(f)
	first := true
	for sc.Scan() {
		if first {
			first = false
			continue
		}
		fields := strings.Fields(sc.Text())
		if len(fields) < 4 {
			continue
		}
		ip, mac := fields[0], fields[3]
		if mac == "00:00:00:00:00:00" || !validMAC(mac) {
			continue
		}
		if err := upsertDevice(db, ip, mac); err == nil {
			updated++
		}
	}
	return updated, sc.Err()
}

func validMAC(mac string) bool {
	_, err := net.ParseMAC(mac)
	return err == nil
}

func upsertDevice(db *gorm.DB, ip, mac string) error {
	var dev models.Device
	err := db.Where("mac = ?", mac).First(&dev).Error
	now := time.Now()
	if err == gorm.ErrRecordNotFound {
		return db.Create(&models.Device{
			MAC:       mac,
			IP:        ip,
			FirstSeen: now,
			LastSeen:  now,
		}).Error
	}
	if err != nil {
		return err
	}
	return db.Model(&dev).Updates(map[string]interface{}{
		"ip":        ip,
		"last_seen": now,
	}).Error
}

// ResolveHostname attempts reverse DNS for display only.
func ResolveHostname(ip string) string {
	names, err := net.LookupAddr(ip)
	if err != nil || len(names) == 0 {
		return ""
	}
	return strings.TrimSuffix(names[0], ".")
}
