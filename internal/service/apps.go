package service

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/docker/docker/client"
)

type App struct {
	ID          string   `json:"id"`
	Key         string   `json:"key"`
	Name        string   `json:"name"`
	Category    string   `json:"category"`
	Description string   `json:"description"`
	Icon        string   `json:"icon"`
	Versions    []string `json:"versions"`
	DefaultVersion string `json:"default_version"`
	Installed   bool     `json:"installed"`
	InstalledVersion string `json:"installed_version"`
}

type InstallAppRequest struct {
	AppKey  string                 `json:"app_key"`
	Version string                 `json:"version"`
	Name    string                 `json:"name"`
	Config  map[string]interface{} `json:"config"`
}

type AppService struct {
	cli      *client.Client
	dataPath string
}

func NewAppService() (*AppService, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, err
	}
	
		dataPath := "./data/apps"
	os.MkdirAll(dataPath, 0755)
	
	return &AppService{
		cli:      cli,
		dataPath: dataPath,
	}, nil
}

func (s *AppService) Close() error {
	return s.cli.Close()
}

func (s *AppService) GetApps() []App {
	return []App{
		{ID: "1", Key: "nginx", Name: "Nginx", Category: "web", Description: "高性能的HTTP和反向代理服务器", Icon: "Monitor", Versions: []string{"1.24", "1.22"}, DefaultVersion: "1.24"},
		{ID: "2", Key: "openresty", Name: "OpenResty", Category: "web", Description: "基于Nginx与Lua的高性能Web平台", Icon: "Monitor", Versions: []string{"latest"}, DefaultVersion: "latest"},
		{ID: "3", Key: "mysql", Name: "MySQL", Category: "database", Description: "流行的关系型数据库", Icon: "Coin", Versions: []string{"8.0", "5.7"}, DefaultVersion: "8.0"},
		{ID: "4", Key: "postgresql", Name: "PostgreSQL", Category: "database", Description: "强大的开源关系型数据库", Icon: "Coin", Versions: []string{"15", "14"}, DefaultVersion: "15"},
		{ID: "5", Key: "redis", Name: "Redis", Category: "database", Description: "高性能的键值对数据库", Icon: "Connection", Versions: []string{"7.2"}, DefaultVersion: "7.2"},
		{ID: "6", Key: "php", Name: "PHP", Category: "environment", Description: "流行的通用脚本语言", Icon: "Document", Versions: []string{"8.2", "8.1", "8.0", "7.4"}, DefaultVersion: "8.2"},
		{ID: "7", Key: "phpmyadmin", Name: "phpMyAdmin", Category: "tools", Description: "MySQL可视化管理工具", Icon: "Tools", Versions: []string{"latest"}, DefaultVersion: "latest"},
		{ID: "8", Key: "wordpress", Name: "WordPress", Category: "website", Description: "流行的博客和内容管理系统", Icon: "Document", Versions: []string{"latest", "6.4"}, DefaultVersion: "latest"},
		// v0.1.9 新增
		{ID: "15", Key: "caddy", Name: "Caddy", Category: "web", Description: "自动HTTPS的极简Web服务器", Icon: "Monitor", Versions: []string{"latest", "2"}, DefaultVersion: "latest"},
		{ID: "16", Key: "mariadb", Name: "MariaDB", Category: "database", Description: "MySQL替代品，开源关系型数据库", Icon: "Coin", Versions: []string{"11", "10"}, DefaultVersion: "11"},
		{ID: "17", Key: "mongodb", Name: "MongoDB", Category: "database", Description: "文档型NoSQL数据库", Icon: "Coin", Versions: []string{"7.0", "6.0"}, DefaultVersion: "7.0"},
		{ID: "18", Key: "gitea", Name: "Gitea", Category: "tools", Description: "轻量级Git代码托管服务", Icon: "Tools", Versions: []string{"latest", "1.21"}, DefaultVersion: "latest"},
		{ID: "19", Key: "uptime-kuma", Name: "Uptime Kuma", Category: "tools", Description: "网站状态监控与告警", Icon: "Tools", Versions: []string{"latest"}, DefaultVersion: "latest"},
		{ID: "20", Key: "grafana", Name: "Grafana", Category: "tools", Description: "监控可视化仪表盘", Icon: "Tools", Versions: []string{"latest", "10"}, DefaultVersion: "latest"},
		{ID: "21", Key: "netdata", Name: "Netdata", Category: "tools", Description: "实时服务器性能监控", Icon: "Tools", Versions: []string{"latest"}, DefaultVersion: "latest"},
	}
}

func (s *AppService) InstallApp(req *InstallAppRequest) error {
	appPath := filepath.Join(s.dataPath, req.Name)
	if err := os.MkdirAll(appPath, 0755); err != nil {
		return err
	}
	
	// 创建 html 目录
	htmlPath := filepath.Join(appPath, "html")
	os.MkdirAll(htmlPath, 0755)
	
	composeContent := s.generateDockerCompose(req, appPath)
	composePath := filepath.Join(appPath, "docker-compose.yml")
	if err := os.WriteFile(composePath, []byte(composeContent), 0644); err != nil {
		return err
	}
	
	cmd := exec.Command("docker", "compose", "-f", composePath, "up", "-d")
	cmd.Dir = appPath
	return cmd.Run()
}

func (s *AppService) generateDockerCompose(req *InstallAppRequest, appPath string) string {
	switch req.AppKey {
	case "nginx":
		return s.generateNginxCompose(req, appPath)
	case "openresty":
		return s.generateOpenRestyCompose(req, appPath)
	case "mysql":
		return s.generateMySQLCompose(req, appPath)
	case "postgresql":
		return s.generatePostgreSQLCompose(req, appPath)
	case "redis":
		return s.generateRedisCompose(req, appPath)
	case "php":
		return s.generatePHPCompose(req, appPath)
	case "wordpress":
		case "wordpress":
			return s.generateWordPressCompose(req, appPath)
		case "caddy":
			return s.generateCaddyCompose(req, appPath)
		case "mariadb":
			return s.generateMariaDBCompose(req, appPath)
		case "mongodb":
			return s.generateMongoDBCompose(req, appPath)
		case "gitea":
			return s.generateGiteaCompose(req, appPath)
		case "uptime-kuma":
			return s.generateUptimeKumaCompose(req, appPath)
		case "grafana":
			return s.generateGrafanaCompose(req, appPath)
		case "netdata":
			return s.generateNetdataCompose(req, appPath)
		default:
			return s.generateDefaultCompose(req, appPath)
		}
	}

func (s *AppService) generateCaddyCompose(req *InstallAppRequest, appPath string) string {
		port := "8080"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		return fmt.Sprintf(`version: '3.8'
services:
  caddy:
    image: caddy:%s
    container_name: upanel_%s
    ports:
      - "%s:80"
      - "%s:443"
    volumes:
      - %s/data:/data
      - %s/config:/config
    restart: unless-stopped
`, req.Version, req.Name, port, port, appPath, appPath)
	}

func (s *AppService) generateMariaDBCompose(req *InstallAppRequest, appPath string) string {
		port := "3306"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		password := "mariadb123"
		if p, ok := req.Config["password"].(string); ok && p != "" {
			password = p
		}
		return fmt.Sprintf(`version: '3.8'
services:
  mariadb:
    image: mariadb:%s
    container_name: upanel_%s
    environment:
      MYSQL_ROOT_PASSWORD: %s
      MYSQL_DATABASE: upanel
    ports:
      - "%s:3306"
    volumes:
      - %s/data:/var/lib/mysql
    restart: unless-stopped
`, req.Version, req.Name, password, port, appPath)
	}

func (s *AppService) generateMongoDBCompose(req *InstallAppRequest, appPath string) string {
		port := "27017"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		password := "mongodb123"
		if p, ok := req.Config["password"].(string); ok && p != "" {
			password = p
		}
		return fmt.Sprintf(`version: '3.8'
services:
  mongodb:
    image: mongo:%s
    container_name: upanel_%s
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: %s
    ports:
      - "%s:27017"
    volumes:
      - %s/data:/data/db
    restart: unless-stopped
`, req.Version, req.Name, password, port, appPath)
	}

func (s *AppService) generateGiteaCompose(req *InstallAppRequest, appPath string) string {
		port := "3000"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		sshPort := "2222"
		if p, ok := req.Config["ssh_port"].(int); ok && p > 0 {
			sshPort = fmt.Sprintf("%d", p)
		}
		return fmt.Sprintf(`version: '3.8'
services:
  gitea:
    image: gitea/gitea:%s
    container_name: upanel_%s
    environment:
      USER_UID: 1000
      USER_GID: 1000
    ports:
      - "%s:3000"
      - "%s:22"
    volumes:
      - %s/data:/data
    restart: unless-stopped
`, req.Version, req.Name, port, sshPort, appPath)
	}

func (s *AppService) generateUptimeKumaCompose(req *InstallAppRequest, appPath string) string {
		port := "3001"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		return fmt.Sprintf(`version: '3.8'
services:
  uptime-kuma:
    image: louislam/uptime-kuma:%s
    container_name: upanel_%s
    ports:
      - "%s:3001"
    volumes:
      - %s/data:/app/data
    restart: unless-stopped
`, req.Version, req.Name, port, appPath)
	}

func (s *AppService) generateGrafanaCompose(req *InstallAppRequest, appPath string) string {
		port := "3000"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		return fmt.Sprintf(`version: '3.8'
services:
  grafana:
    image: grafana/grafana:%s
    container_name: upanel_%s
    ports:
      - "%s:3000"
    volumes:
      - %s/data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    restart: unless-stopped
`, req.Version, req.Name, port, appPath)
	}

func (s *AppService) generateNetdataCompose(req *InstallAppRequest, appPath string) string {
		port := "19999"
		if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
		}
		return fmt.Sprintf(`version: '3.8'
services:
  netdata:
    image: netdata/netdata:%s
    container_name: upanel_%s
    hostname: upanel_server
    ports:
      - "%s:19999"
    volumes:
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - %s/data:/var/cache/netdata
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    restart: unless-stopped
`, req.Version, req.Name, port, appPath)
}
func (s *AppService) generateNginxCompose(req *InstallAppRequest, appPath string) string {
	port := "8080"
	if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
	}
	
	return fmt.Sprintf(`version: '3.8'
services:
  nginx:
    image: nginx:%s
    container_name: upanel_%s
    ports:
      - "%s:80"
    volumes:
      - %s/html:/usr/share/nginx/html
      - %s/conf:/etc/nginx/conf.d
    restart: unless-stopped
`, req.Version, req.Name, port, appPath, appPath)
}

func (s *AppService) generateOpenRestyCompose(req *InstallAppRequest, appPath string) string {
	port := "8080"
	if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
	}
	
	return fmt.Sprintf(`version: '3.8'
services:
  openresty:
    image: openresty/openresty:%s
    container_name: upanel_%s
    ports:
      - "%s:80"
    volumes:
      - %s/html:/usr/local/openresty/nginx/html
      - %s/conf:/etc/nginx/conf.d
    restart: unless-stopped
`, req.Version, req.Name, port, appPath, appPath)
}

func (s *AppService) generateMySQLCompose(req *InstallAppRequest, appPath string) string {
	port := "3306"
	if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
	}
	password := "root123"
	if p, ok := req.Config["password"].(string); ok && p != "" {
		password = p
	}
	
	return fmt.Sprintf(`version: '3.8'
services:
  mysql:
    image: mysql:%s
    container_name: upanel_%s
    environment:
      MYSQL_ROOT_PASSWORD: %s
    ports:
      - "%s:3306"
    volumes:
      - %s/data:/var/lib/mysql
    restart: unless-stopped
`, req.Version, req.Name, password, port, appPath)
}

func (s *AppService) generatePostgreSQLCompose(req *InstallAppRequest, appPath string) string {
	port := "5432"
	if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
	}
	password := "postgres123"
	if p, ok := req.Config["password"].(string); ok && p != "" {
		password = p
	}
	
	return fmt.Sprintf(`version: '3.8'
services:
  postgres:
    image: postgres:%s
    container_name: upanel_%s
    environment:
      POSTGRES_PASSWORD: %s
    ports:
      - "%s:5432"
    volumes:
      - %s/data:/var/lib/postgresql/data
    restart: unless-stopped
`, req.Version, req.Name, password, port, appPath)
}

func (s *AppService) generateRedisCompose(req *InstallAppRequest, appPath string) string {
	port := "6379"
	if p, ok := req.Config["port"].(int); ok && p > 0 {
		port = fmt.Sprintf("%d", p)
	}
	
	return fmt.Sprintf(`version: '3.8'
services:
  redis:
    image: redis:%s
    container_name: upanel_%s
    ports:
      - "%s:6379"
    volumes:
      - %s/data:/data
    restart: unless-stopped
`, req.Version, req.Name, port, appPath)
}

func (s *AppService) generatePHPCompose(req *InstallAppRequest, appPath string) string {
	return fmt.Sprintf(`version: '3.8'
services:
  php:
    image: php:%s-fpm
    container_name: upanel_%s
    volumes:
      - %s/www:/var/www/html
    restart: unless-stopped
`, req.Version, req.Name, appPath)
}

func (s *AppService) generateDefaultCompose(req *InstallAppRequest, appPath string) string {
	return fmt.Sprintf(`version: '3.8'
services:
  app:
    image: %s:%s
    container_name: upanel_%s
    restart: unless-stopped
`, req.AppKey, req.Version, req.Name)
}
