package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rakshak/rakshak/internal/auth"
	"github.com/rakshak/rakshak/internal/blocklist"
	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/discovery"
	"github.com/rakshak/rakshak/internal/models"
	"gorm.io/gorm"
)

type Handler struct {
	cfg *config.Config
	db  *gorm.DB
}

func NewHandler(cfg *config.Config, db *gorm.DB) *Handler {
	return &Handler{cfg: cfg, db: db}
}

func (h *Handler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "rakshak-api"})
}

func (h *Handler) Login(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	token, user, err := auth.Login(h.db, h.cfg.SecretKey, req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"user":  gin.H{"id": user.ID, "email": user.Email, "role": user.Role},
	})
}

func (h *Handler) DashboardStats(c *gin.Context) {
	var blockedToday, allowedToday int64
	today := time.Now().Truncate(24 * time.Hour)
	h.db.Model(&models.DNSQueryLog{}).Where("timestamp >= ? AND action = ?", today, "blocked").Count(&blockedToday)
	h.db.Model(&models.DNSQueryLog{}).Where("timestamp >= ? AND action = ?", today, "allowed").Count(&allowedToday)

	var devices int64
	h.db.Model(&models.Device{}).Count(&devices)

	var lastVersion models.BlocklistVersion
	h.db.Order("id desc").First(&lastVersion)

	c.JSON(http.StatusOK, gin.H{
		"queries_blocked_today": blockedToday,
		"queries_allowed_today": allowedToday,
		"devices_total":         devices,
		"blocklist_version":     lastVersion.Version,
		"blocklist_domains":     lastVersion.TotalDomains,
		"lan_ip":                h.cfg.LanIP,
	})
}

func (h *Handler) ListDevices(c *gin.Context) {
	var devices []models.Device
	h.db.Order("last_seen desc").Find(&devices)
	c.JSON(http.StatusOK, devices)
}

func (h *Handler) UpdateDevice(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Hostname string  `json:"hostname"`
		GroupID  *string `json:"group_id"`
		PolicyID *string `json:"policy_id"`
		Blocked  *bool   `json:"blocked"`
		Notes    string  `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updates := map[string]interface{}{}
	if req.Hostname != "" {
		updates["hostname"] = req.Hostname
	}
	if req.GroupID != nil {
		updates["group_id"] = req.GroupID
	}
	if req.PolicyID != nil {
		updates["policy_id"] = req.PolicyID
	}
	if req.Blocked != nil {
		updates["blocked"] = *req.Blocked
	}
	if req.Notes != "" {
		updates["notes"] = req.Notes
	}
	if err := h.db.Model(&models.Device{}).Where("id = ?", id).Updates(updates).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "device not found"})
		return
	}
	auth.Audit(h.db, c.GetString("user_id"), "device.update", id)
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func (h *Handler) DiscoverDevices(c *gin.Context) {
	n, err := discovery.ScanARPTable(h.db)
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"discovered": n})
}

func (h *Handler) ListPolicies(c *gin.Context) {
	var policies []models.Policy
	h.db.Find(&policies)
	c.JSON(http.StatusOK, policies)
}

func (h *Handler) UpdatePolicy(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		BlockAds       *bool  `json:"block_ads"`
		BlockTrackers  *bool  `json:"block_trackers"`
		BlockMalware   *bool  `json:"block_malware"`
		BlockPhishing  *bool  `json:"block_phishing"`
		BlockScam      *bool  `json:"block_scam"`
		BlockTelemetry *bool  `json:"block_telemetry"`
		BlockMiners    *bool  `json:"block_miners"`
		BlockExploits  *bool  `json:"block_exploits"`
		SafeSearch     *bool  `json:"safe_search"`
		CustomAllowlist *string `json:"custom_allowlist"`
		CustomBlocklist *string `json:"custom_blocklist"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updates := map[string]interface{}{}
	if req.BlockAds != nil {
		updates["block_ads"] = *req.BlockAds
	}
	if req.BlockTrackers != nil {
		updates["block_trackers"] = *req.BlockTrackers
	}
	if req.BlockMalware != nil {
		updates["block_malware"] = *req.BlockMalware
	}
	if req.BlockPhishing != nil {
		updates["block_phishing"] = *req.BlockPhishing
	}
	if req.BlockScam != nil {
		updates["block_scam"] = *req.BlockScam
	}
	if req.BlockTelemetry != nil {
		updates["block_telemetry"] = *req.BlockTelemetry
	}
	if req.BlockMiners != nil {
		updates["block_miners"] = *req.BlockMiners
	}
	if req.BlockExploits != nil {
		updates["block_exploits"] = *req.BlockExploits
	}
	if req.SafeSearch != nil {
		updates["safe_search"] = *req.SafeSearch
	}
	if req.CustomAllowlist != nil {
		updates["custom_allowlist"] = *req.CustomAllowlist
	}
	if req.CustomBlocklist != nil {
		updates["custom_blocklist"] = *req.CustomBlocklist
	}
	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no fields to update"})
		return
	}
	if err := h.db.Model(&models.Policy{}).Where("id = ?", id).Updates(updates).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	auth.Audit(h.db, c.GetString("user_id"), "policy.update", id)
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func (h *Handler) ListFeeds(c *gin.Context) {
	var feeds []models.BlocklistFeed
	h.db.Find(&feeds)
	c.JSON(http.StatusOK, feeds)
}

func (h *Handler) UpdateFeed(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Enabled *bool `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Enabled != nil {
		h.db.Model(&models.BlocklistFeed{}).Where("id = ?", id).Update("enabled", *req.Enabled)
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func (h *Handler) TriggerBlocklistUpdate(c *gin.Context) {
	merger := blocklist.NewMerger(h.cfg, h.db)
	count, version, err := merger.UpdateAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	auth.Audit(h.db, c.GetString("user_id"), "blocklist.update", version)
	c.JSON(http.StatusOK, gin.H{"domains": count, "version": version})
}

func (h *Handler) TopBlocked(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	type row struct {
		Domain string
		Count  int64
	}
	var rows []row
	h.db.Model(&models.DNSQueryLog{}).
		Select("domain, count(*) as count").
		Where("action = ? AND timestamp > ?", "blocked", time.Now().AddDate(0, 0, -1)).
		Group("domain").
		Order("count desc").
		Limit(limit).
		Scan(&rows)
	c.JSON(http.StatusOK, rows)
}

func (h *Handler) QueryLogs(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))
	action := c.Query("action")
	q := h.db.Order("timestamp desc").Limit(limit)
	if action != "" {
		q = q.Where("action = ?", action)
	}
	var logs []models.DNSQueryLog
	q.Find(&logs)
	c.JSON(http.StatusOK, logs)
}

func (h *Handler) IngestQueryLog(c *gin.Context) {
	// Called by CoreDNS log plugin webhook or sidecar
	var req struct {
		ClientIP  string `json:"client_ip"`
		Domain    string `json:"domain"`
		QueryType string `json:"query_type"`
		Action    string `json:"action"`
		Category  string `json:"category"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	var deviceID *string
	var dev models.Device
	if h.db.Where("ip = ?", req.ClientIP).First(&dev).Error == nil {
		deviceID = &dev.ID
	}
	h.db.Create(&models.DNSQueryLog{
		Timestamp: time.Now(),
		ClientIP:  req.ClientIP,
		Domain:    req.Domain,
		QueryType: req.QueryType,
		Action:    req.Action,
		Category:  req.Category,
		DeviceID:  deviceID,
	})
	c.Status(http.StatusAccepted)
}

func (h *Handler) SystemInfo(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"version":     "1.0.0",
		"lan_ip":      h.cfg.LanIP,
		"block_ip":    h.cfg.BlockIP,
		"upstream":    h.cfg.Upstream,
		"force_dns":   h.cfg.ForceDNS,
		"dns_port":    53,
	})
}
