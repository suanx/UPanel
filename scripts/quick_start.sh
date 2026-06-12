#!/bin/bash

# --- 颜色输出 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_title() { echo -e "${CYAN}$1${NC}"; }

# --- 打印 Banner ---
print_banner() {
    echo ""
    print_title "╔══════════════════════════════════════════════════════════╗"
    print_title "║                                                          ║"
    print_title "║   ██╗   ██╗██████╗  █████╗ ███╗   ██╗███████╗██╗        ║"
    print_title "║   ██║   ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██║        ║"
    print_title "║   ██║   ██║██████╔╝███████║██╔██╗ ██║█████╗  ██║        ║"
    print_title "║   ██║   ██║██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║        ║"
    print_title "║   ╚██████╔╝██║     ██║  ██║██║ ╚████║███████╗███████╗   ║"
    print_title "║    ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝   ║"
    print_title "║                                                          ║"
    print_title "║              轻量级容器管理面板 - 一键安装               ║"
    print_title "╚══════════════════════════════════════════════════════════╝"
    echo ""
}

# --- 检测操作系统 ---
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "无法检测操作系统类型。"
        exit 1
    fi
    ARCH=$(uname -m)
    print_info "检测到系统: ${OS} ${VER}, 架构: ${ARCH}"
}

# --- 检查 Docker ---
check_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker 已安装"
        return 0
    else
        return 1
    fi
}

# --- 安装 Docker ---
install_docker() {
    print_warn "未检测到 Docker，是否安装？[y/N]"
    read -r install_docker_choice
    if [[ "$install_docker_choice" =~ ^[Yy]$ ]]; then
        print_info "正在安装 Docker..."
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
        print_info "Docker 安装完成。"
    else
        print_error "UPanel 需要 Docker 环境，安装已终止。"
        exit 1
    fi
}

# --- 交互式配置 ---
interactive_config() {
    echo ""
    print_title "┌─────────────────────────────────────────────────────────────┐"
    print_title "│                      安装配置向导                           │"
    print_title "└─────────────────────────────────────────────────────────────┘"
    echo ""

    # 安装目录
    DEFAULT_DIR="/opt/upanel"
    read -p "请输入安装目录 [${DEFAULT_DIR}]: " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

    # 面板端口
    DEFAULT_PORT="8080"
    read -p "请输入面板端口 [${DEFAULT_PORT}]: " PANEL_PORT
    PANEL_PORT=${PANEL_PORT:-$DEFAULT_PORT}

    # 管理员用户名
    DEFAULT_USER="admin"
    read -p "请输入管理员用户名 [${DEFAULT_USER}]: " PANEL_USER
    PANEL_USER=${PANEL_USER:-$DEFAULT_USER}

    # 管理员密码
    echo ""
    echo "请选择密码设置方式:"
    echo "  1) 自动生成随机密码"
    echo "  2) 手动输入密码"
    read -p "请选择 [1]: " PASSWORD_CHOICE
    PASSWORD_CHOICE=${PASSWORD_CHOICE:-1}

    if [[ "$PASSWORD_CHOICE" == "2" ]]; then
        read -sp "请输入管理员密码: " PANEL_PASS
        echo ""
        read -sp "请再次输入密码: " PANEL_PASS_CONFIRM
        echo ""
        if [[ "$PANEL_PASS" != "$PANEL_PASS_CONFIRM" ]]; then
            print_error "两次输入的密码不一致"
            exit 1
        fi
    else
        PANEL_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
        print_info "自动生成密码: ${PANEL_PASS}"
    fi

    # 安全入口
    PANEL_ENTRY=$(tr -dc a-z0-9 </dev/urandom | head -c 8)

    # 确认配置
    echo ""
    print_title "┌─────────────────────────────────────────────────────────────┐"
    print_title "│                      安装配置确认                           │"
    print_title "└─────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  安装目录: ${YELLOW}${INSTALL_DIR}${NC}"
    echo "  面板端口: ${YELLOW}${PANEL_PORT}${NC}"
    echo "  管理员账号: ${YELLOW}${PANEL_USER}${NC}"
    echo "  管理员密码: ${YELLOW}${PANEL_PASS}${NC}"
    echo "  安全入口: ${YELLOW}${PANEL_ENTRY}${NC}"
    echo ""
    read -p "确认以上配置？[Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi
}

# --- 下载并解压 ---
download_upanel() {
    local api_url="https://api.github.com/repos/suanx/UPanel/releases/latest"
    local tmp_file="/tmp/upanel-latest.tar.gz"

    print_info "正在获取最新版本信息..."
    local download_url=$(curl -s "$api_url" | grep "browser_download_url.*linux-amd64.tar.gz" | head -1 | cut -d '"' -f 4)

    if [[ -z "$download_url" ]]; then
        print_error "无法获取下载链接"
        exit 1
    fi

    print_info "正在下载 UPanel..."
    if ! curl -L --fail -o "$tmp_file" "$download_url"; then
        print_error "下载失败"
        exit 1
    fi

    print_info "解压到 ${INSTALL_DIR}..."
    mkdir -p "$INSTALL_DIR"
    if ! tar -xzf "$tmp_file" -C "$INSTALL_DIR"; then
        print_error "解压失败"
        exit 1
    fi
    rm -f "$tmp_file"
}

# --- 配置后端 ---
configure_backend() {
    print_info "配置后端服务..."
    cat > ${INSTALL_DIR}/.env << EOF
PANEL_PORT=${PANEL_PORT}
JWT_SECRET=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 32)
PANEL_ENTRY=${PANEL_ENTRY}
EOF
}

# --- 配置 systemd 服务 ---
configure_service() {
    print_info "配置 systemd 服务..."
    cat > /etc/systemd/system/upanel.service << EOF
[Unit]
Description=UPanel Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/bin/upanel
Restart=always
RestartSec=10
EnvironmentFile=${INSTALL_DIR}/.env

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable upanel
    print_info "服务配置完成"
}

# --- 启动面板 ---
start_upanel() {
    print_info "启动 UPanel..."
    systemctl start upanel
    sleep 3
    if systemctl is-active --quiet upanel; then
        print_info "UPanel 启动成功"
    else
        print_error "UPanel 启动失败，请检查日志: journalctl -u upanel -f"
        exit 1
    fi
}
# --- 配置 Nginx（可选）---
configure_nginx() {
    print_info "是否配置 Nginx 反向代理？[y/N]"
    read -r setup_nginx

    if [[ "$setup_nginx" =~ ^[Yy]$ ]]; then
        if ! command -v nginx &> /dev/null; then
            print_info "正在安装 Nginx..."
            apt update && apt install -y nginx
        fi

        cat > /etc/nginx/sites-available/upanel << 'EOFA'
server {
    listen 80;
    server_name _;

    location / {
        root /opt/upanel/web;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOFA

        ln -sf /etc/nginx/sites-available/upanel /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        systemctl restart nginx
        print_info "Nginx 配置完成"
        PANEL_PORT=80
    fi
}

# --- 输出安装信息 ---
print_summary() {
    local server_ip=$(curl -s ifconfig.me)

    echo ""
    print_title "════════════════════════════════════════════════════════════"
    print_title "                    UPanel 安装完成！                        "
    print_title "════════════════════════════════════════════════════════════"
    echo ""

    if [[ "$PANEL_PORT" == "80" ]]; then
        echo -e "  🌐 访问地址: ${GREEN}http://${server_ip}${NC}"
    else
        echo -e "  🌐 访问地址: ${GREEN}http://${server_ip}:${PANEL_PORT}${NC}"
    fi

    if [[ -n "$PANEL_ENTRY" ]]; then
        echo -e "  🔐 安全入口: ${GREEN}${PANEL_ENTRY}${NC}"
    fi

    echo -e "  👤 用户名:   ${GREEN}${PANEL_USER}${NC}"
    echo -e "  🔑 密码:     ${GREEN}${PANEL_PASS}${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠️  请务必保存好您的密码！后续无法再次查看。${NC}"
    echo ""
    echo -e "  📌 管理命令:"
    echo -e "     启动: ${YELLOW}systemctl start upanel${NC}"
    echo -e "     停止: ${YELLOW}systemctl stop upanel${NC}"
    echo -e "     状态: ${YELLOW}systemctl status upanel${NC}"
    echo -e "     日志: ${YELLOW}journalctl -u upanel -f${NC}"
    echo ""
    if [[ "$PANEL_PORT" != "80" ]]; then
        echo -e "  ${YELLOW}💡 提示: 请在服务器安全组中放行端口 ${PANEL_PORT}${NC}"
    fi
    echo ""
}

# --- 主流程 ---
main() {
    print_banner
    detect_os
    check_docker || install_docker
    interactive_config
    download_upanel
    configure_backend
    configure_service
    configure_nginx
    start_upanel
    print_summary
}

main "$@"
