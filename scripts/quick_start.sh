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

# 从终端读取输入（兼容 curl | bash 管道模式）
# 用法同 read 命令：read_input -p "提示" [-s] VAR
read_input() {
    local prompt="" silent=false var_name=""
    local i=0 args=("$@")
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            -p|--prompt) prompt="${args[$((i+1))]}"; i=$((i+2)) ;;
            -s|--silent) silent=true; i=$((i+1)) ;;
            -sp) prompt="${args[$((i+1))]}"; silent=true; i=$((i+2)) ;;
            *) var_name="${args[$i]}"; i=$((i+1)) ;;
        esac
    done

    if [[ -t 0 ]]; then
        # 直接运行，有终端
        if $silent; then read -p "$prompt" -s "$var_name"; echo; else read -p "$prompt" "$var_name"; fi
    else
        # 管道模式，从 /dev/tty 读取
        echo -n "$prompt" > /dev/tty
        if $silent; then
            stty -echo < /dev/tty 2>/dev/null
            read "$var_name" < /dev/tty
            stty echo < /dev/tty 2>/dev/null
            echo > /dev/tty
        else
            read "$var_name" < /dev/tty
        fi
    fi
}
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
    read_input install_docker_choice
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
    read_input -p "请输入安装目录 [${DEFAULT_DIR}]: " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_DIR}

    # 面板端口
    DEFAULT_PORT="8080"
    read_input -p "请输入面板端口 [${DEFAULT_PORT}]: " PANEL_PORT
    PANEL_PORT=${PANEL_PORT:-$DEFAULT_PORT}

    # 管理员用户名
    DEFAULT_USER="admin"
    read_input -p "请输入管理员用户名 [${DEFAULT_USER}]: " PANEL_USER
    PANEL_USER=${PANEL_USER:-$DEFAULT_USER}

    # 管理员密码
    echo ""
    echo "请选择密码设置方式:"
    echo "  1) 自动生成随机密码"
    echo "  2) 手动输入密码"
    read_input -p "请选择 [1]: " PASSWORD_CHOICE
    PASSWORD_CHOICE=${PASSWORD_CHOICE:-1}

    if [[ "$PASSWORD_CHOICE" == "2" ]]; then
        read_input -sp "请输入管理员密码: " PANEL_PASS
        echo ""
        read_input -sp "请再次输入密码: " PANEL_PASS_CONFIRM
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
    read_input -p "确认以上配置？[Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi
}

# --- 获取源码目录（脚本所在项目的根目录）---
get_project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    # 如果 scripts/quick_start.sh 在项目中，则项目根是脚本目录的父目录
    if [[ -f "$script_dir/../go.mod" ]]; then
        cd "$script_dir/.." && pwd
    elif [[ -f "$script_dir/go.mod" ]]; then
        cd "$script_dir" && pwd
    else
        echo ""
    fi
}

# --- 检查编译环境 ---
check_build_env() {
    if ! command -v go &>/dev/null; then
        print_error "Go 未安装，无法编译后端"
        print_info "请先安装 Go 1.21+，或创建 GitHub Release 后重试"
        return 1
    fi
    if ! command -v node &>/dev/null; then
        print_error "Node.js 未安装，无法编译前端"
        print_info "请先安装 Node.js 18+，或创建 GitHub Release 后重试"
        return 1
    fi
    print_info "编译环境检测通过 (Go + Node.js)"
    return 0
}

# --- 从源码编译 ---
build_from_source() {
    local project_root="$1"

    print_info "从源码编译 UPanel..."

    cd "$project_root" || { print_error "无法进入项目目录"; exit 1; }

    # 编译后端
    print_info "编译后端..."
    mkdir -p "$INSTALL_DIR/bin"
    if ! CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-s -w -X main.Version=dev" \
        -o "$INSTALL_DIR/bin/upanel" \
        cmd/upanel/main.go 2>&1; then
        print_error "后端编译失败"
        exit 1
    fi
    if [[ -f "$INSTALL_DIR/bin/upanel" ]]; then
        chmod +x "$INSTALL_DIR/bin/upanel"
        print_info "后端编译完成: $(ls -lh "$INSTALL_DIR/bin/upanel" | awk '{print $5}')"
    fi

    # 编译 CLI 工具
    if ! CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-s -w" \
        -o "$INSTALL_DIR/bin/up" \
        cmd/upanel/cli/main.go 2>&1; then
        print_warn "CLI 工具编译失败（可忽略）"
    fi

    # 编译前端
    print_info "编译前端..."
    if [[ -d "$project_root/web" ]]; then
        cd "$project_root/web"
        if [[ ! -d "node_modules" ]]; then
            npm install
        fi
        if ! npm run build; then
            print_error "前端编译失败"
            exit 1
        fi
        mkdir -p "$INSTALL_DIR/web"
        cp -r dist/* "$INSTALL_DIR/web/"
        cd "$project_root"
        print_info "前端编译完成"
    fi
}

# --- 使用已有预编译二进制 ---
use_existing_binary() {
    local project_root="$1"

    print_info "使用已有预编译二进制..."

    mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/web" "$INSTALL_DIR/data"

    # 尝试多个可能的位置
    local binary=""
    for candidate in \
        "$project_root/upanel-linux" \
        "$project_root/release/upanel/bin/upanel" \
        "$project_root/bin/upanel"; do
        if [[ -f "$candidate" ]]; then
            binary="$candidate"
            break
        fi
    done

    if [[ -z "$binary" ]]; then
        print_error "未找到预编译二进制文件"
        return 1
    fi

    cp "$binary" "$INSTALL_DIR/bin/upanel"
    chmod +x "$INSTALL_DIR/bin/upanel"
    print_info "后端二进制已部署: $binary"

    # CLI 工具
    for candidate in "$project_root/up-linux" "$project_root/bin/up"; do
        if [[ -f "$candidate" ]]; then
            cp "$candidate" "$INSTALL_DIR/bin/up"
            chmod +x "$INSTALL_DIR/bin/up"
            print_info "CLI 工具已部署"
            break
        fi
    done

    # 编译前端（需要 Node.js）
    if [[ -d "$project_root/web" ]]; then
        if ! command -v node &>/dev/null; then
            print_error "需要 Node.js 编译前端"
            print_info "请安装 Node.js 18+ 后重试"
            return 1
        fi
        print_info "编译前端..."
        cd "$project_root/web"
        if [[ ! -d "node_modules" ]]; then
            npm install
        fi
        if npm run build; then
            cp -r dist/* "$INSTALL_DIR/web/"
            cd "$project_root"
            print_info "前端编译完成"
        else
            cd "$project_root"
            print_error "前端编译失败"
            return 1
        fi
    fi

    return 0
}

# --- 从 GitHub Releases 下载 ---
download_from_release() {
    local api_url="https://api.github.com/repos/suanx/UPanel/releases/latest"
    local tmp_file="/tmp/upanel-latest.tar.gz"

    print_info "正在获取最新版本信息..."
    local download_url
    download_url=$(curl -s "$api_url" | grep "browser_download_url.*linux-amd64.tar.gz" | head -1 | cut -d '"' -f 4)

    if [[ -z "$download_url" ]]; then
        print_warn "GitHub Releases 中未找到 linux-amd64 包"
        return 1
    fi

    print_info "正在下载 UPanel..."
    if ! curl -L --fail -o "$tmp_file" "$download_url"; then
        print_warn "下载失败"
        return 1
    fi

    print_info "解压到 ${INSTALL_DIR}..."
    mkdir -p "$INSTALL_DIR"
    # 包内有 upanel/ 前缀目录，用 strip-components 去掉
    if ! tar -xzf "$tmp_file" -C "$INSTALL_DIR" --strip-components=1; then
        print_warn "解压失败"
        rm -f "$tmp_file"
        return 1
    fi
    chmod +x "$INSTALL_DIR/bin/upanel" "$INSTALL_DIR/bin/up" 2>/dev/null || true
    rm -f "$tmp_file"
    return 0
}

# --- 准备 UPanel 文件（自动选择最佳方式）---
prepare_upanel() {
    local project_root
    project_root="$(get_project_root)"

    # 方式 1：优先从 GitHub Releases 下载
    print_info "尝试从 GitHub Releases 下载..."
    if download_from_release; then
        print_info "从 GitHub Releases 下载成功"
        return 0
    fi

    # 方式 2：有源码且编译环境齐全 → 从源码编译
    if [[ -n "$project_root" ]] && [[ -f "$project_root/go.mod" ]]; then
        print_info "检测到项目源码目录: $project_root"
        if check_build_env; then
            build_from_source "$project_root"
            print_info "源码编译部署成功"
            return 0
        fi
    fi

    # 方式 3：有源码 + 预编译二进制 → 直接用
    if [[ -n "$project_root" ]]; then
        if use_existing_binary "$project_root"; then
            print_info "使用本地预编译二进制部署成功"
            return 0
        fi
    fi

    # 全部失败
    print_error "╔══════════════════════════════════════════════════════════════╗"
    print_error "║                    部署失败                                  ║"
    print_error "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    print_error "未能获取 UPanel 程序文件，原因："
    echo "  • GitHub Releases 尚未创建，无法下载"
    echo "  • 未找到项目源码目录（go.mod）"
    echo "  • 未找到预编译二进制文件"
    echo ""
    print_info "解决方法："
    echo "  方法 A：克隆仓库后在本地执行"
    echo "    git clone https://github.com/suanx/UPanel.git"
    echo "    cd UPanel && bash scripts/quick_start.sh"
    echo ""
    echo "  方法 B：在 GitHub 仓库创建 Release 后重试"
    echo "    https://github.com/suanx/UPanel/releases"
    echo ""
    echo "  方法 C：用 deploy.sh 手动打包部署"
    echo "    bash scripts/deploy.sh pack --secret '密钥' --entry xxxxxxxx"
    echo "    然后将 build/ 下的 tar.gz 上传到服务器解压安装"
    echo ""
    exit 1
}

# --- 配置后端 ---
configure_backend() {
    print_info "配置后端服务..."
    cat > ${INSTALL_DIR}/.env << EOF
PANEL_PORT=${PANEL_PORT}
PANEL_USER=${PANEL_USER}
PANEL_PASS=${PANEL_PASS}
JWT_SECRET=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 32)
PANEL_ENTRY=${PANEL_ENTRY}
EOF

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
    read_input setup_nginx

    if [[ "$setup_nginx" =~ ^[Yy]$ ]]; then
        if ! command -v nginx &> /dev/null; then
            print_info "正在安装 Nginx..."
            apt update && apt install -y nginx
        fi

        print_info "写入 Nginx 配置..."
        cat > /etc/nginx/sites-available/upanel <<NGINXEOF
server {
    listen 80;
    server_name _;

    location / {
        root ${INSTALL_DIR}/web;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${PANEL_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINXEOF
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
    local base_url="http://${server_ip}:${PANEL_PORT}"
    echo -e "  🌐 访问地址: ${GREEN}${base_url}${NC}"

    if [[ -n "$PANEL_ENTRY" ]]; then
        echo -e "  🔐 安全入口: ${GREEN}${PANEL_ENTRY}${NC}"
        echo -e "  📍 完整地址: ${GREEN}${base_url}/${PANEL_ENTRY}${NC}"
        echo -e "  ${YELLOW}⚠️  请通过完整地址访问面板，直接访问端口会返回 404${NC}"
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
    prepare_upanel
    configure_backend
    configure_service
    configure_nginx
    start_upanel
    print_summary
}

main "$@"
