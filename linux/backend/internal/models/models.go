package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID           string    `gorm:"primaryKey" json:"id"`
	Email        string    `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string    `gorm:"not null" json:"-"`
	Role         string    `gorm:"not null;default:admin" json:"role"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = uuid.New().String()
	}
	return nil
}

type Device struct {
	ID          string     `gorm:"primaryKey" json:"id"`
	MAC         string     `gorm:"uniqueIndex" json:"mac"`
	IP          string     `gorm:"index" json:"ip"`
	Hostname    string     `json:"hostname"`
	Vendor      string     `json:"vendor"`
	GroupID     *string    `gorm:"index" json:"group_id"`
	PolicyID    *string    `gorm:"index" json:"policy_id"`
	FirstSeen   time.Time  `json:"first_seen"`
	LastSeen    time.Time  `json:"last_seen"`
	Blocked     bool       `gorm:"default:false" json:"blocked"`
	Notes       string     `json:"notes"`
}

func (d *Device) BeforeCreate(tx *gorm.DB) error {
	if d.ID == "" {
		d.ID = uuid.New().String()
	}
	return nil
}

type DeviceGroup struct {
	ID          string `gorm:"primaryKey" json:"id"`
	Name        string `gorm:"uniqueIndex;not null" json:"name"`
	Description string `json:"description"`
	PolicyID    string `gorm:"not null" json:"policy_id"`
}

func (g *DeviceGroup) BeforeCreate(tx *gorm.DB) error {
	if g.ID == "" {
		g.ID = uuid.New().String()
	}
	return nil
}

type Policy struct {
	ID              string `gorm:"primaryKey" json:"id"`
	Name            string `gorm:"uniqueIndex;not null" json:"name"`
	BlockAds        bool   `gorm:"default:true" json:"block_ads"`
	BlockTrackers   bool   `gorm:"default:true" json:"block_trackers"`
	BlockMalware    bool   `gorm:"default:true" json:"block_malware"`
	BlockPhishing   bool   `gorm:"default:true" json:"block_phishing"`
	BlockScam       bool   `gorm:"default:true" json:"block_scam"`
	BlockTelemetry  bool   `gorm:"default:true" json:"block_telemetry"`
	BlockMiners     bool   `gorm:"default:true" json:"block_miners"`
	BlockExploits   bool   `gorm:"default:true" json:"block_exploits"`
	SafeSearch      bool   `gorm:"default:false" json:"safe_search"`
	CustomAllowlist string `gorm:"type:text" json:"custom_allowlist"`
	CustomBlocklist string `gorm:"type:text" json:"custom_blocklist"`
}

func (p *Policy) BeforeCreate(tx *gorm.DB) error {
	if p.ID == "" {
		p.ID = uuid.New().String()
	}
	return nil
}

type DNSQueryLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Timestamp time.Time `gorm:"index" json:"timestamp"`
	ClientIP  string    `gorm:"index" json:"client_ip"`
	Domain    string    `gorm:"index" json:"domain"`
	QueryType string    `json:"query_type"`
	Action    string    `gorm:"index" json:"action"` // allowed, blocked, cached
	Category  string    `json:"category"`
	DeviceID  *string   `json:"device_id"`
}

type BlocklistFeed struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	Name        string    `gorm:"uniqueIndex" json:"name"`
	URL         string    `json:"url"`
	Category    string    `json:"category"`
	Enabled     bool      `gorm:"default:true" json:"enabled"`
	LastUpdated time.Time `json:"last_updated"`
	LastStatus  string    `json:"last_status"`
	EntryCount  int       `json:"entry_count"`
}

func (f *BlocklistFeed) BeforeCreate(tx *gorm.DB) error {
	if f.ID == "" {
		f.ID = uuid.New().String()
	}
	return nil
}

type BlocklistVersion struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Version   string    `gorm:"index" json:"version"`
	AppliedAt time.Time `json:"applied_at"`
	TotalDomains int    `json:"total_domains"`
	Checksum  string    `json:"checksum"`
}

type SystemSetting struct {
	Key   string `gorm:"primaryKey" json:"key"`
	Value string `gorm:"type:text" json:"value"`
}

type AuditLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Timestamp time.Time `gorm:"index" json:"timestamp"`
	UserID    string    `json:"user_id"`
	Action    string    `json:"action"`
	Detail    string    `gorm:"type:text" json:"detail"`
}
