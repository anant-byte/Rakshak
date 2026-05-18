package api

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rakshak/rakshak/internal/auth"
	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/middleware"
	"gorm.io/gorm"
)

func RegisterRoutes(r *gin.Engine, cfg *config.Config, db *gorm.DB) {
	h := NewHandler(cfg, db)

	r.GET("/health", h.Health)

	v1 := r.Group("/api/v1")
	{
		v1.POST("/auth/login", middleware.LoginRateLimit(10, time.Minute), h.Login)
		v1.POST("/internal/query-log", middleware.InternalOnly(cfg.InternalSecret), h.IngestQueryLog)

		authed := v1.Group("")
		authed.Use(auth.Middleware(cfg.SecretKey))
		{
			authed.GET("/dashboard/stats", h.DashboardStats)
			authed.GET("/system/info", h.SystemInfo)

			authed.GET("/devices", h.ListDevices)
			authed.PATCH("/devices/:id", h.UpdateDevice)
			authed.POST("/devices/discover", h.DiscoverDevices)

			authed.GET("/policies", h.ListPolicies)
			authed.PATCH("/policies/:id", h.UpdatePolicy)

			authed.GET("/blocklists/feeds", h.ListFeeds)
			authed.PATCH("/blocklists/feeds/:id", h.UpdateFeed)
			authed.POST("/blocklists/update", h.TriggerBlocklistUpdate)

			authed.GET("/logs/queries", h.QueryLogs)
			authed.GET("/analytics/top-blocked", h.TopBlocked)
		}
	}
}
