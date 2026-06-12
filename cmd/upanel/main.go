package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"upanel/internal/config"
	"upanel/internal/handler"
	"upanel/internal/middleware"
)

var Version = "v0.1.8"

func main() {
	// 加载配置
	if err := config.LoadConfig(); err != nil {
		log.Printf("配置加载失败: %v", err)
	}

	// 设置 Gin 模式
	gin.SetMode(config.AppConfig.Mode)

	// 创建必要的目录
	os.MkdirAll(config.AppConfig.DataPath, 0755)
	os.MkdirAll(config.AppConfig.StaticPath, 0755)

	r := gin.Default()

	// 允许跨域
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type,Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	entryPath := config.AppConfig.GetSecurityEntry()
	staticPath := config.AppConfig.StaticPath

	// ========== 静态文件服务 ==========
	if _, err := os.Stat(staticPath); err == nil {
		r.Static("/assets", filepath.Join(staticPath, "assets"))
		r.StaticFile("/favicon.ico", filepath.Join(staticPath, "favicon.ico"))
		r.StaticFile("/vite.svg", filepath.Join(staticPath, "vite.svg"))
		r.StaticFile("/icons.svg", filepath.Join(staticPath, "icons.svg"))

		if entryPath != "" {
			// 有安全入口：根路径返回 404 隐藏面板
			r.GET(entryPath, func(c *gin.Context) {
				c.File(filepath.Join(staticPath, "index.html"))
			})
			r.GET(entryPath+"/*any", func(c *gin.Context) {
				c.File(filepath.Join(staticPath, "index.html"))
			})
			r.NoRoute(func(c *gin.Context) {
				if strings.HasPrefix(c.Request.URL.Path, "/api") {
					c.JSON(404, gin.H{"error": "API not found"})
					return
				}
				c.String(404, "Not Found")
			})
		} else {
			r.NoRoute(func(c *gin.Context) {
				if strings.HasPrefix(c.Request.URL.Path, "/api") {
					c.JSON(404, gin.H{"error": "API not found"})
					return
				}
				c.File(filepath.Join(staticPath, "index.html"))
			})
		}
	}

	// ========== API 路由（始终在 /api/ 下） ==========
	api := r.Group("/api")
	{
		// 认证相关
		authHandler := handler.NewAuthHandler()
		api.POST("/auth/login", authHandler.Login)
		api.POST("/auth/logout", authHandler.Logout)

		// 需要认证的路由组
		authorized := api.Group("/")
		authorized.Use(middleware.AuthMiddleware())
		{
			authorized.GET("/auth/userinfo", authHandler.GetUserInfo)
			authorized.POST("/auth/change-password", authHandler.ChangePassword)

			// 系统信息
			systemHandler, err := handler.NewSystemHandler()
			if err != nil {
				log.Printf("系统服务初始化失败: %v", err)
			} else {
				defer systemHandler.Close()
				authorized.GET("/system/info", systemHandler.GetInfo)
			}

			// Docker 版本
			authorized.GET("/docker/version", func(c *gin.Context) {
				c.JSON(200, gin.H{"version": "Docker v29.4.0"})
			})

			// 容器管理
			containerHandler, err := handler.NewContainerHandler()
			if err != nil {
				log.Printf("容器服务初始化失败: %v", err)
			} else {
				defer containerHandler.Close()
				containers := authorized.Group("/containers")
				{
					containers.GET("/", containerHandler.List)
					containers.POST("/:id/start", containerHandler.Start)
					containers.POST("/:id/stop", containerHandler.Stop)
					containers.POST("/:id/restart", containerHandler.Restart)
					containers.DELETE("/:id", containerHandler.Remove)
					containers.GET("/:id/logs", containerHandler.Logs)
				}
			}

			// 文件管理
			fileHandler := handler.NewFileHandler()
			files := authorized.Group("/files")
			{
				files.GET("/list", fileHandler.List)
				files.GET("/content", fileHandler.GetContent)
				files.POST("/content", fileHandler.SaveContent)
				files.POST("/folder", fileHandler.CreateFolder)
				files.POST("/file", fileHandler.CreateFile)
				files.PUT("/rename", fileHandler.Rename)
				files.DELETE("/delete", fileHandler.Delete)
				files.POST("/upload", fileHandler.Upload)
			}

			// 网站管理
			websiteHandler, err := handler.NewWebsiteHandler()
			if err != nil {
				log.Printf("网站服务初始化失败: %v", err)
			} else {
				defer websiteHandler.Close()
				websites := authorized.Group("/websites")
				{
					websites.POST("/", websiteHandler.Create)
					websites.GET("/", websiteHandler.List)
					websites.POST("/:domain/start", websiteHandler.Start)
					websites.POST("/:domain/stop", websiteHandler.Stop)
					websites.DELETE("/:domain", websiteHandler.Delete)
					websites.GET("/:domain/url", websiteHandler.GetURL)
				}
			}

			// 数据库管理
			databaseHandler, err := handler.NewDatabaseHandler()
			if err != nil {
				log.Printf("数据库服务初始化失败: %v", err)
			} else {
				defer databaseHandler.Close()
				databases := authorized.Group("/databases")
				{
					databases.POST("/", databaseHandler.Create)
					databases.GET("/", databaseHandler.List)
					databases.POST("/:name/start", databaseHandler.Start)
					databases.POST("/:name/stop", databaseHandler.Stop)
					databases.POST("/:name/restart", databaseHandler.Restart)
					databases.DELETE("/:name", databaseHandler.Delete)
					databases.GET("/:name/connection", databaseHandler.GetConnectionInfo)
				}
			}

			// 应用商店
			appsHandler, err := handler.NewAppsHandler()
			if err != nil {
				log.Printf("应用商店服务初始化失败: %v", err)
			} else {
				defer appsHandler.Close()
				apps := authorized.Group("/apps")
				{
					apps.GET("/", appsHandler.List)
					apps.POST("/install", appsHandler.Install)
				}
			}

			// 系统设置
			settingsHandler := handler.NewSettingsHandler()
			authorized.GET("/settings", settingsHandler.GetAll)
			authorized.PUT("/settings", settingsHandler.Update)

			// Docker 配置
			dockerHandler := handler.NewDockerHandler()
			docker := authorized.Group("/docker")
			{
				docker.GET("/config", dockerHandler.GetConfig)
				docker.PUT("/config", dockerHandler.UpdateConfig)
				docker.POST("/restart", dockerHandler.RestartDocker)
			}
		}
	}

	// 启动服务器
	addr := ":" + config.AppConfig.Port
	fmt.Printf("🚀 UPanel %s 启动成功\n", Version)
	if entryPath != "" {
		fmt.Printf("📍 访问地址: http://localhost%s%s\n", addr, entryPath)
	} else {
		fmt.Printf("📍 监听地址: http://localhost%s\n", addr)
	}
	r.Run(addr)
}
