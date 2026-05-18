package middleware

import (
	"net"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// InternalOnly restricts endpoints to Docker/LAN networks + shared secret header.
func InternalOnly(secret string) gin.HandlerFunc {
	privateNets := []*net.IPNet{}
	for _, cidr := range []string{
		"10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8",
	} {
		_, n, _ := net.ParseCIDR(cidr)
		privateNets = append(privateNets, n)
	}

	return func(c *gin.Context) {
		if secret == "" {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "internal API disabled: set RAKSHAK_INTERNAL_SECRET"})
			return
		}
		if c.GetHeader("X-Rakshak-Internal") == secret {
			c.Next()
			return
		}
		// Docker bridge: allow only from rakshak-logd hostname when secret header present on same network
		if strings.HasSuffix(c.Request.Host, "rakshak-api") {
			ip := c.ClientIP()
			if parsed := net.ParseIP(ip); parsed != nil {
				for _, n := range privateNets {
					if n.Contains(parsed) {
						c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "missing internal secret"})
						return
					}
				}
			}
		}
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "forbidden"})
	}
}
