package main

import (
	"context"
	"log"
	"net/http"
	"strings"

	"github.com/Nerzal/gocloak/v13"
	"github.com/gin-gonic/gin"
)

var (
	keycloakURL  = "http://localhost:8080"
	realm        = "myrealm"
	clientID     = "backend-client"
	clientSecret = "your-backend-client-secret"
	client       = gocloak.NewClient(keycloakURL)
)

func main() {
	r := gin.Default()
	r.Use(CORSMiddleware())

	r.GET("/public", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "Public endpoint"})
	})

	r.GET("/private", KeycloakAuthMiddleware(), func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "Private endpoint - Authenticated!"})
	})

	log.Println("Server running on :8081")
	r.Run(":8081")
}

func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func KeycloakAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header missing"})
			c.Abort()
			return
		}

		// Extract the token from "Bearer <token>"
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Authorization header format"})
			c.Abort()
			return
		}

		tokenStr := tokenParts[1]

		// Decode and Validate Access Token
		ctx := context.Background()
		decodedToken, _, err := client.DecodeAccessToken(ctx, tokenStr, realm)
		// fmt.Printf("%+v\n", decodedToken)

		if err != nil || decodedToken == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		c.Next()
	}
}
