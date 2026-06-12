# Changelog

## v0.1.8 (2026-06-12)

### 🐛 Bug 修复

- **修复安装时自定义用户名/密码不生效** — `auth.go` 改为从环境变量 `PANEL_USER` / `PANEL_PASS` 读取用户凭据，安装脚本写入 `.env` 后生效
- 默认用户仍为 `admin / admin123`（不设置环境变量时）

---

## v0.1.7 (2026-06-12)

### 🐛 Bug 修复

- **彻底修复前端路由刷新 404** — Vue Router 改用 `createWebHashHistory`，# 号后的路由不发送到服务器，刷新始终加载入口页面
- **修复 401 跳转** — axios 拦截器的 `/login` 跳转改为 hash 模式
- **修复 main.go 代码缩进** — API 路由嵌套在 if 块内的结构问题

---

## v0.1.6 (2026-06-12)

### 🐛 Bug 修复

- **修复安全入口 `PANEL_ENTRY` 路由** — 配置安全入口后访问 `/{entry}` 可正常加载前端，根路径 `/` 返回 404 防扫描
- **修复前端空白 / 404 问题** — 加载前端后 Vue Router 正常路由，添加 catch-all 重定向到登录页
- **修复 Release 包解压路径** — `quick_start.sh` 解压时使用 `--strip-components=1` 解决包内前缀目录问题
- **修复管道模式下输入交互** — `read_input` 函数支持 `curl | bash` 模式从 `/dev/tty` 读取

### ⚙️ 优化

- `quick_start.sh` 安装完成后显示完整访问地址（含安全入口）

---

## v0.1.5 (2026-06-12)

### ✨ 新特性

- 添加自动化部署脚本 `scripts/deploy.sh`（支持 pack/deploy/install 三种模式）
- 添加 CI/CD 工作流 `.github/workflows/release.yml`（自动构建+发布 Release）
- 添加 `scripts/quick_start.sh` 服务器一键安装脚本

### 📝 文档

- 完善 README.md（项目介绍、功能说明、四种部署方式、配置说明、管理命令）
- 添加 CHANGELOG.md 更新日志

### 🔧 优化

- 优化 systemd 服务配置，改为 EnvironmentFile 加载 .env
- 添加 `.gitignore` 排除编译产物和敏感配置
- 统一版本号为 v0.1.5

---

## v0.1.4 (2026-05-28)

- 达芬奇主题优化 + 主题系统精简
- 修复已知问题

## v0.1.3 (2026-05-15)

- 添加应用商店功能
- 优化容器管理界面

## v0.1.2 (2026-04-30)

- 添加文件管理功能
- 添加数据库管理功能
- 基础 Docker 容器管理

## v0.1.1 (2026-04-15)

- 系统监控面板
- JWT 认证机制

## v0.1.0 (2026-04-01)

- 项目初始化
- Gin + Vue 3 基础框架
