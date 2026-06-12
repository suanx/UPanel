# Changelog

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
