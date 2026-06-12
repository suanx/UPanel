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

项目提供两个脚本，分别适用于**普通装机**和**开发者部署**两种场景。

---

### 方式一：服务器一键安装 ⭐ 推荐

适合**没有任何开发环境的全新服务器**，交互式引导，自动完成所有步骤。

脚本会自动选择最佳的安装来源：

| 优先级 | 来源 | 条件 |
|---|---|---|
| 🥇 | GitHub Releases 下载 | 仓库已创建 Release |
| 🥈 | 本地源码编译 | 在克隆的仓库中执行，有 Go + Node 环境 |
| 🥉 | 预编译二进制 + 编译前端 | 本地有 `upanel-linux` 二进制 |

#### 场景 A：在克隆的仓库目录中执行（推荐）

```bash
git clone https://github.com/suanx/UPanel.git
cd UPanel
bash scripts/quick_start.sh
```

脚本会自动检测到源码，调用 Go + Node 编译后安装。

#### 场景 B：服务器远程执行（需要 GitHub 已创建 Release）

```bash
curl -fsSL https://raw.githubusercontent.com/suanx/UPanel/main/scripts/quick_start.sh | bash
```

运行后跟着交互提示走：
```
检测系统 → 检查/安装 Docker → 配置安装目录、端口、密码
→ 获取 UPanel 程序（Release/编译/二进制） → 配置 systemd 服务
→ 可选 Nginx 反代 → 启动面板 → 输出访问信息
```

### 方式二：开发者部署脚本

适合**本地有 Go + Node 开发环境**，需要编译、打包、部署到远程服务器。

| 命令 | 适用场景 | 说明 |
|---|---|---|
| `pack` | 本地构建 → 打包 tar.gz | 在自己的电脑上编译后打包，上传到服务器解压安装 |
| `deploy` | 本地构建 → 直接推送到远程服务器 | 一条命令完成编译、上传、远程安装全流程 |
| `install` | 已有部署包 → 服务器上安装 | 部署包已解压到目标目录后，执行此命令配置服务 |

```bash
# 1. 仅打包（生成 build/upanel-xxx.tar.gz）
bash scripts/deploy.sh pack --secret '你的密钥' --entry a8x3k9m2

# 2. 一键部署到远程服务器（编译→打包→上传→安装一气呵成）
bash scripts/deploy.sh deploy \
  --ssh-host 123.45.67.89 \
  --secret '你的密钥' \
  --entry a8x3k9m2

# 3. 服务器上直接安装（部署包已上传解压后执行）
bash scripts/deploy.sh install --port 8080 --secret '你的密钥' --entry a8x3k9m2
```

### 方式三：手动部署（预编译包）

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

### 方式四：从源码编译

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
