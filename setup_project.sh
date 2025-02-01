#!/bin/bash

set -e  # Exit on error

# Project Name
PROJECT_NAME="keycloak-app"

echo "🚀 Setting up the project: $PROJECT_NAME"

# Create project directories
mkdir -p $PROJECT_NAME/{backend,frontend}
cd $PROJECT_NAME

# Initialize Backend (Golang + Gin)
echo "📦 Setting up Backend..."
cd backend
go mod init backend
go get github.com/gin-gonic/gin github.com/Nerzal/gocloak/v11 github.com/dgrijalva/jwt-go

# Create backend files
cat <<EOL > main.go
package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/Nerzal/gocloak/v11"
)

var (
	keycloakURL  = "http://localhost:8080"
	realm        = "myrealm"
	clientID     = "backend-client"
	clientSecret = "your-backend-client-secret"
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
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		client := gocloak.NewClient(keycloakURL)
		_, claims, err := client.DecodeAccessToken(c, token, realm, clientID, clientSecret)
		if err != nil || claims == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Token"})
			c.Abort()
			return
		}

		c.Next()
	}
}
EOL

cd ..

# Initialize Frontend (React)
echo "🎨 Setting up Frontend..."
npx create-react-app frontend
cd frontend
npm install keycloak-js axios

# Create frontend files
cat <<EOL > src/keycloak.js
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
    url: 'http://localhost:8080/',
    realm: 'myrealm',
    clientId: 'frontend-client',
});

export default keycloak;
EOL

cat <<EOL > src/App.js
import React, { useEffect, useState } from 'react';
import Keycloak from './keycloak';
import axios from 'axios';

function App() {
    const [keycloak, setKeycloak] = useState(null);
    const [authenticated, setAuthenticated] = useState(false);
    const [message, setMessage] = useState('');

    useEffect(() => {
        const initKeycloak = async () => {
            const kc = Keycloak;
            const authenticated = await kc.init({ onLoad: 'login-required' });

            setKeycloak(kc);
            setAuthenticated(authenticated);
        };

        initKeycloak();
    }, []);

    const fetchPublicData = async () => {
        const response = await axios.get('http://localhost:8081/public');
        setMessage(response.data.message);
    };

    const fetchPrivateData = async () => {
        if (!keycloak) return;
        try {
            const response = await axios.get('http://localhost:8081/private', {
                headers: { Authorization: \`Bearer \${keycloak.token}\` },
            });
            setMessage(response.data.message);
        } catch (error) {
            setMessage('Access Denied');
        }
    };

    return (
        <div>
            {keycloak ? (
                authenticated ? (
                    <div>
                        <h1>Welcome {keycloak.tokenParsed.preferred_username}</h1>
                        <button onClick={fetchPublicData}>Public Data</button>
                        <button onClick={fetchPrivateData}>Private Data</button>
                        <button onClick={() => keycloak.logout()}>Logout</button>
                        <p>{message}</p>
                    </div>
                ) : (
                    <h2>Unable to authenticate!</h2>
                )
            ) : (
                <h2>Initializing Keycloak...</h2>
            )}
        </div>
    );
}

export default App;
EOL

cd ..

# Create Docker Compose
echo "🐳 Creating Docker Compose..."
cat <<EOL > docker-compose.yml
version: "3"
services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=admin
    ports:
      - "8080:8080"
    command: start-dev

  backend:
    build: ./backend
    ports:
      - "8081:8081"
    depends_on:
      - keycloak

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - keycloak
      - backend
EOL

# Instructions
echo "✅ Project Setup Complete!"
echo "📌 Next Steps:"
echo "1️⃣ Start Keycloak: docker-compose up -d keycloak"
echo "2️⃣ Run Backend: cd backend && go run main.go"
echo "3️⃣ Run Frontend: cd frontend && npm start"
echo "🚀 Visit: http://localhost:3000"

