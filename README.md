# UPanel 轻量级服务器管理面板

> 一款开源的轻量级服务器管理面板，基于 Go + Vue 3 构建，专注于容器化环境下的高效运维。

[![Go Version](https://img.shields.io/badge/Go-1.25-blue)](https://go.dev/)
[![Vue](https://img.shields.io/badge/Vue-3.5-4FC08D)](https://vuejs.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.1.5-orange)](https://github.com/suanx/UPanel/releases)

---

## 🎯 核心功能

### 🖥️ 系统监控
- 实时查看 CPU、内存、磁盘、网络 IO
- 系统进程与负载概览

### 🐳 Docker 容器管理
- 容器列表查看、启动、停止、重启、删除
- 容器实时日志查看
- Docker 配置管理

### 📂 文件管理
- 可视化文件浏览、编辑、新建、删除
- 文件上传、重命名
- 在线编辑保存

### 🌐 网站管理
- Nginx 站点创建与管理
- 站点启停控制

### 🗄️ 数据库管理
- 数据库实例创建与启停
- 连接信息查看

### 🛒 应用商店
- 一键安装常用应用
- 应用列表浏览

### 🔐 安全特性
- JWT 认证机制
- 安全入口路径（防扫描）
- 密码 bcrypt 加密
- 跨域安全控制

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────┐
│                  前端 (Vue 3)                     │
│  Element Plus + ECharts + Axios + Tailwind CSS   │
└──────────────────────┬──────────────────────────┘
                       │ HTTP/API
┌──────────────────────▼──────────────────────────┐
│               后端 (Go + Gin)                    │
│  认证 ⋮ 容器 ⋮ 文件 ⋮ 站点 ⋮ 数据库 ⋮ 监控      │
└──────┬────────────────────────────┬─────────────┘
       │                            │
       ▼                            ▼
   Docker Engine               Linux System
   (容器管理)                  (文件/进程/监控)
```

| 层级 | 技术栈 |
|---|---|
| **后端语言** | Go 1.25 |
| **Web 框架** | Gin v1.9 |
| **前端框架** | Vue 3.5 + Vite 5 |
| **UI 组件** | Element Plus 2.9 |
| **图表** | ECharts 6 |
| **认证** | JWT (HS256) + bcrypt |
| **Docker SDK** | Docker API v20.10 |
| **系统监控** | gopsutil v3 |

---

## 🚀 快速部署

### 环境要求

| 项 | 要求 |
|---|---|
| 操作系统 | Linux (amd64 / arm64) |
| Docker | 已安装并运行（核心依赖） |
| systemd | 用于服务管理 |
| 权限 | root 用户执行 |

### 方式一：自动化部署脚本 ⭐推荐

项目提供 `scripts/deploy.sh` 自动化部署脚本，支持三种模式：

| 命令 | 说明 |
|---|---|
| `pack` | 本地构建并打包为 tar.gz |
| `deploy` | 打包并一键部署到远程服务器 |
| `install` | 在服务器上从部署包直接安装 |

```bash
# 1. 本地打包
bash scripts/deploy.sh pack --secret '你的密钥' --entry a8x3k9m2

# 2. 一键部署到远程服务器
bash scripts/deploy.sh deploy \
  --ssh-host 123.45.67.89 \
  --secret '你的密钥' \
  --entry a8x3k9m2 \
  --port 8080

# 3. 服务器上直接安装（已解压部署包后）
bash scripts/deploy.sh install --port 8080 --secret '你的密钥' --entry a8x3k9m2
```

### 方式二：手动部署（预编译包）

项目 Release 已提供 Linux amd64 预编译二进制，约 4MB，无需编译环境。

```bash
# 1. 下载 Release 包
wget https://github.com/suanx/UPanel/releases/download/v0.1.5/upanel-v0.1.5-linux-amd64.tar.gz

# 2. 解压到安装目录
mkdir -p /opt/upanel
tar -xzf upanel-v0.1.5-linux-amd64.tar.gz -C /opt/upanel

# 3. 构建前端
cd web && npm install && npm run build
scp -r dist/* root@服务器IP:/opt/upanel/web/

# 4. 配置环境变量
cat > /opt/upanel/.env << 'EOF'
PANEL_PORT=8080
JWT_SECRET=你的随机密钥（建议32位以上）
PANEL_ENTRY=a8x3k9m2
EOF

# 5. 注册 systemd 服务
cat > /etc/systemd/system/upanel.service << 'EOF'
[Unit]
Description=UPanel Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/upanel
ExecStart=/opt/upanel/bin/upanel
Restart=always
RestartSec=10
EnvironmentFile=/opt/upanel/.env

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动服务
systemctl daemon-reload
systemctl enable --now upanel
```

### 方式三：从源码编译

```bash
# 编译后端
make build

# 编译前端
cd web && npm install && npm run build && cd ..

# 部署到 /opt/upanel...
```

---

## 📝 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `PANEL_PORT` | `8080` | 面板监听端口 |
| `GIN_MODE` | `release` | Gin 运行模式 (`debug` / `release` / `test`) |
| `JWT_SECRET` | `upanel-default-secret-key-2024` | 🔴 **务必修改！** JWT 签名密钥 |
| `STATIC_PATH` | `./web` | 前端静态文件目录 |
| `DATA_PATH` | `./data` | 数据存储目录 |
| `DB_PATH` | `./data/upanel.db` | SQLite 数据库路径 |
| `PANEL_ENTRY` | `""` | 🔴 **建议设置！** 安全入口路径（防扫描） |

### 默认账号

| 项 | 值 |
|---|---|
| 用户名 | `admin` |
| 密码 | `admin123`（首次登录后立即修改！） |

---

## 🔧 管理命令

### systemd

```bash
systemctl status upanel    # 查看状态
systemctl start upanel     # 启动
systemctl stop upanel      # 停止
systemctl restart upanel   # 重启
journalctl -u upanel -f    # 实时日志
```

### CLI 工具（up）

```bash
up 0          # 检查服务状态
up 1          # 启动服务
up 2          # 停止服务
up 3          # 重启服务
up 5          # 卸载面板
up 6          # 查看用户信息
up 8          # 查看版本
up 9 username 用户名      # 修改用户名
up 9 password 密码        # 修改密码
up 9 port 端口号          # 修改端口
up 10         # 重置配置
```

---

## 🧪 验证部署

```bash
# 检查服务
systemctl status upanel

# 测试 API
curl http://localhost:8080/api/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 浏览器访问
# http://服务器IP:8080
```

---

## ⚠️ 安全建议

1. **更换 JWT_SECRET** — 部署前务必修改 `.env` 中的密钥
2. **修改默认密码** — 部署后立即修改 admin 密码
3. **设置安全入口** — 建议配置 `PANEL_ENTRY` 随机路径
4. **防火墙限制** — 仅放行必要端口，或使用 Nginx 反代 + HTTPS
5. **定期更新** — 关注 GitHub Release 获取最新版本

---

## 📦 项目结构

```
UPanel/
├── cmd/
│   └── upanel/
│       ├── main.go         # 后端主程序入口
│       └── cli/main.go     # CLI 命令行工具
├── internal/
│   ├── config/             # 配置加载
│   ├── handler/            # API 处理器
│   ├── middleware/         # 中间件（认证等）
│   └── service/            # 业务逻辑层
├── web/                    # 前端 Vue 3 项目
│   ├── src/
│   │   ├── views/          # 页面视图
│   │   ├── layouts/        # 布局组件
│   │   ├── router/         # 路由配置
│   │   └── composables/    # 组合式 API
│   └── vite.config.js      # Vite 配置
├── scripts/
│   ├── deploy.sh           # 自动化部署脚本
│   ├── quick_start.sh      # 一键安装脚本
│   └── upanel.service      # systemd 服务模板
├── release/                # 预编译发布包
├── Makefile                # 编译构建
└── go.mod                  # Go 模块定义
```

---

## 🔗 相关链接

- **GitHub**: [https://github.com/suanx/UPanel](https://github.com/suanx/UPanel)
- **Issues**: [提交 Issue](https://github.com/suanx/UPanel/issues)
- **Releases**: [下载页面](https://github.com/suanx/UPanel/releases)

---

> **UPanel** — 轻量、高效、开源的服务器管理面板
