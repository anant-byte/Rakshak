package server

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/rakshak/rakshak/internal/api"
	"github.com/rakshak/rakshak/internal/blocklist"
	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/db"
)

func Run(cfg *config.Config) error {
	database, err := db.Open(cfg)
	if err != nil {
		return err
	}
	if err := db.Seed(cfg, database); err != nil {
		return err
	}

	// Initial blocklist build on first boot
	merger := blocklist.NewMerger(cfg, database)
	if n, ver, err := merger.UpdateAll(); err != nil {
		log.Printf("warn: initial blocklist update: %v", err)
	} else {
		log.Printf("blocklist ready: %d domains, version %s", n, ver)
	}

	if cfg.LogLevel == "debug" {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery(), gin.Logger(), corsMiddleware(cfg))

	api.RegisterRoutes(r, cfg, database)

	log.Printf("RAKSHAK API listening on %s", cfg.ListenAddr)
	return r.Run(cfg.ListenAddr)
}

func corsMiddleware(cfg *config.Config) gin.HandlerFunc {
	origins := make(map[string]bool)
	for _, o := range cfg.CORSOrigins {
		origins[o] = true
	}
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origins[origin] || origins["*"] {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
			c.Header("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
		}
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
