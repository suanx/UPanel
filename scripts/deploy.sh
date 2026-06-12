#!/bin/bash
# ============================================================================
#  UPanel 部署脚本
#  支持两种模式：
#    本地打包模式  — 在本地编译构建并打包为 tar.gz
#    远程部署模式  — 将部署包推送至服务器并一键安装
# ============================================================================

set -e

# ─── 颜色 ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
title() { echo -e "${CYAN}$1${NC}"; }

# ─── 配置（可被环境变量覆盖） ─────────────────────────────────────────────
VERSION="${VERSION:-v0.1.5}"
INSTALL_DIR="${INSTALL_DIR:-/opt/upanel}"
PANEL_PORT="${PANEL_PORT:-8080}"
JWT_SECRET="${JWT_SECRET:-}"
PANEL_ENTRY="${PANEL_ENTRY:-}"
SSH_HOST="${SSH_HOST:-}"
SSH_PORT="${SSH_PORT:-22}"
SSH_USER="${SSH_USER:-root}"
SKIP_BUILD="${SKIP_BUILD:-false}"

# ─── 路径 ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$BUILD_DIR/dist"
PACKAGE_NAME="upanel-${VERSION}-linux-amd64.tar.gz"
PACKAGE_PATH="$BUILD_DIR/$PACKAGE_NAME"

# ─── Banner ────────────────────────────────────────────────────────────────
print_banner() {
    echo ""
    title "╔══════════════════════════════════════════════════════════╗"
    title "║                     UPanel 部署工具                      ║"
    title "║                  ${VERSION} · Linux amd64               ║"
    title "╚══════════════════════════════════════════════════════════╝"
    echo ""
}

# ─── 帮助 ──────────────────────────────────────────────────────────────────
print_help() {
    echo ""
    title "USAGE:"
    echo "  $0 <command> [options]"
    echo ""
    title "COMMANDS:"
    echo "  pack             本地构建并打包为 tar.gz（默认命令）"
    echo "  deploy           打包并部署到远程服务器"
    echo "  install          在本地服务器执行安装（从已解压的部署包）"
    echo "  help             显示帮助信息"
    echo ""
    title "OPTIONS:"
    echo "  --port <port>           面板端口（默认 8080）"
    echo "  --secret <secret>       JWT 密钥（必填，建议 32 位以上）"
    echo "  --entry <path>          安全入口路径（建议设置，如 a8x3k9m2）"
    echo "  --install-dir <dir>     安装目录（默认 /opt/upanel）"
    echo "  --ssh-host <host>       服务器地址（deploy 模式必填）"
    echo "  --ssh-port <port>       服务器 SSH 端口（默认 22）"
    echo "  --ssh-user <user>       SSH 用户（默认 root）"
    echo "  --skip-build            跳过构建，仅打包已有产物"
    echo "  -y                      跳过所有确认提示"
    echo ""
    title "EXAMPLES:"
    echo "  # 仅打包"
    echo "  $0 pack --secret 'my-secret-key' --entry a8x3k9m2"
    echo ""
    echo "  # 打包并部署到远程服务器"
    echo "  $0 deploy --ssh-host 123.45.67.89 \\"
    echo "           --secret 'my-secret-key' \\"
    echo "           --entry a8x3k9m2 \\"
    echo "           --port 8080"
    echo ""
    echo "  # 在服务器上直接安装（已上传部署包并解压到安装目录后）"
    echo "  $0 install --port 8080 --secret 'my-secret-key' --entry a8x3k9m2"
    echo ""
}

# ─── 参数解析 ─────────────────────────────────────────────────────────────
parse_args() {
    COMMAND="${1:-pack}"
    [[ "$COMMAND" =~ ^(pack|deploy|install|help)$ ]] || {
        error "未知命令: $COMMAND"
        print_help
        exit 1
    }

    [[ "$COMMAND" == "help" ]] && { print_help; exit 0; }

    shift 2>/dev/null || true
    AUTO_YES=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port)         PANEL_PORT="$2"; shift 2 ;;
            --secret)       JWT_SECRET="$2"; shift 2 ;;
            --entry)        PANEL_ENTRY="$2"; shift 2 ;;
            --install-dir)  INSTALL_DIR="$2"; shift 2 ;;
            --ssh-host)     SSH_HOST="$2"; shift 2 ;;
            --ssh-port)     SSH_PORT="$2"; shift 2 ;;
            --ssh-user)     SSH_USER="$2"; shift 2 ;;
            --skip-build)   SKIP_BUILD=true; shift ;;
            -y)             AUTO_YES=true; shift ;;
            *)              error "未知参数: $1"; print_help; exit 1 ;;
        esac
    done

    # 参数校验
    if [[ -z "$JWT_SECRET" ]]; then
        warn "未指定 --secret，将自动生成随机 JWT 密钥"
        JWT_SECRET=$(tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom 2>/dev/null | head -c 32 || echo "$(date +%s)$RANDOM$(date +%N)" | sha256sum | head -c 32)
        info "生成的 JWT_SECRET: ${JWT_SECRET}"
    fi

    if [[ -z "$PANEL_ENTRY" ]]; then
        PANEL_ENTRY=$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 8 || echo "upanel$(date +%s)" | sha256sum | head -c 8)
        info "自动生成安全入口: ${PANEL_ENTRY}"
    fi

    if [[ "$COMMAND" == "deploy" && -z "$SSH_HOST" ]]; then
        error "deploy 模式需要指定 --ssh-host"
        exit 1
    fi
}

# ─── 检查依赖 ──────────────────────────────────────────────────────────────
check_dependencies() {
    info "检查编译环境..."

    local miss=false

    if ! command -v go &>/dev/null; then
        error "Go 未安装，请先安装 Go 1.21+"
        miss=true
    fi

    if ! command -v node &>/dev/null; then
        error "Node.js 未安装，请先安装 Node.js 18+"
        miss=true
    fi

    if ! command -v npm &>/dev/null; then
        error "npm 未安装"
        miss=true
    fi

    # 检查 Go 版本
    if command -v go &>/dev/null; then
        GO_VER=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+')
        if awk "BEGIN{exit !($GO_VER < 1.21)}" 2>/dev/null; then
            error "Go 版本过低 ($GO_VER)，需要 1.21+"
            miss=true
        fi
    fi

    $miss && exit 1
    info "编译环境检查通过 ✓"
}

# ─── 编译后端 ──────────────────────────────────────────────────────────────
build_backend() {
    info "编译后端 (Linux amd64)..."
    cd "$PROJECT_DIR"

    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-s -w -X main.Version=${VERSION}" \
        -o "$DIST_DIR/bin/upanel" \
        cmd/upanel/main.go

    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-s -w" \
        -o "$DIST_DIR/bin/up" \
        cmd/upanel/cli/main.go

    info "后端编译完成 ✓"
    ls -lh "$DIST_DIR/bin/"
}

# ─── 编译前端 ──────────────────────────────────────────────────────────────
build_frontend() {
    info "编译前端..."

    cd "$PROJECT_DIR/web"

    if [[ ! -d "node_modules" ]]; then
        info "安装前端依赖..."
        npm install
    fi

    npm run build
    cp -r dist/* "$DIST_DIR/web/"

    info "前端编译完成 ✓"
}

# ─── 打包 ──────────────────────────────────────────────────────────────────
package() {
    info "打包部署包..."

    # 清理并创建目录结构
    rm -rf "$BUILD_DIR"
    mkdir -p "$DIST_DIR/bin" "$DIST_DIR/web" "$DIST_DIR/scripts"

    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_backend
        build_frontend
    else
        warn "跳过构建，使用已有产物..."
        # 仅复制已有的 bin
        if [[ -f "$PROJECT_DIR/bin/upanel" ]]; then
            cp "$PROJECT_DIR/bin/upanel" "$DIST_DIR/bin/"
            cp "$PROJECT_DIR/bin/up" "$DIST_DIR/bin/" 2>/dev/null || true
        else
            error "未找到编译产物，请先编译或移除 --skip-build"
            exit 1
        fi
        if [[ -d "$PROJECT_DIR/web/dist" ]]; then
            cp -r "$PROJECT_DIR/web/dist/"* "$DIST_DIR/web/"
        else
            error "未找到前端产物 web/dist"
            exit 1
        fi
    fi

    # 生成 .env 模板
    cat > "$DIST_DIR/.env" << EOF
PANEL_PORT=${PANEL_PORT}
JWT_SECRET=${JWT_SECRET}
PANEL_ENTRY=${PANEL_ENTRY}
EOF

    # 复制脚本
    cp "$SCRIPT_DIR/upanel.service" "$DIST_DIR/scripts/"
    cp "$SCRIPT_DIR/deploy.sh" "$DIST_DIR/scripts/" 2>/dev/null || true

    # 生成安装脚本（内嵌到部署包中，供服务器端使用）
    cat > "$DIST_DIR/scripts/install.sh" << 'SCRIPT'
#!/bin/bash
# UPanel 服务器安装脚本（由 deploy.sh 生成）
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 root
[[ $EUID -eq 0 ]] || { error "请使用 root 用户执行"; exit 1; }

# 检查 Docker
if ! command -v docker &>/dev/null; then
    warn "Docker 未安装，是否安装？[y/N]"
    read -r ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
    else
        error "UPanel 需要 Docker 环境"
        exit 1
    fi
fi

INSTALL_DIR="${INSTALL_DIR:-/opt/upanel}"
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/web" "$INSTALL_DIR/data"

# 复制文件
cp "$SRC_DIR/bin/upanel" "$INSTALL_DIR/bin/"
cp "$SRC_DIR/bin/up" "$INSTALL_DIR/bin/" 2>/dev/null || true
cp -r "$SRC_DIR/web/"* "$INSTALL_DIR/web/" 2>/dev/null || true
cp "$SRC_DIR/.env" "$INSTALL_DIR/.env" 2>/dev/null || true

chmod +x "$INSTALL_DIR/bin/upanel" "$INSTALL_DIR/bin/up"

# systemd 服务
cat > /etc/systemd/system/upanel.service << 'SERVICE'
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
SERVICE

# 替换实际路径（避免变量展开问题）
sed -i "s|\${INSTALL_DIR}|${INSTALL_DIR}|g" /etc/systemd/system/upanel.service

systemctl daemon-reload
systemctl enable upanel
systemctl restart upanel

sleep 2
if systemctl is-active --quiet upanel; then
    PORT=$(grep PANEL_PORT "$INSTALL_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "8080")
    ENTRY=$(grep PANEL_ENTRY "$INSTALL_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "")
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

    echo ""
    info "╔══════════════════════════════════════════════════════════╗"
    info "║                   UPanel 安装完成！                     ║"
    info "╚══════════════════════════════════════════════════════════╝"
    echo ""
    info "  访问地址: http://${IP}:${PORT}"
    [[ -n "$ENTRY" ]] && info "  安全入口: ${ENTRY}"
    echo ""
    info "  管理命令:"
    info "    systemctl status upanel    # 查看状态"
    info "    journalctl -u upanel -f    # 查看日志"
    echo ""
    echo -e "${YELLOW}  ⚠️  默认账号: admin / admin123${NC}"
    echo -e "${YELLOW}  ⚠️  首次登录后请立即修改密码！${NC}"
    echo ""
else
    error "UPanel 启动失败，请检查日志: journalctl -u upanel -f"
    exit 1
fi
SCRIPT

    chmod +x "$DIST_DIR/scripts/install.sh"

    # 打包
    cd "$BUILD_DIR"
    tar -czf "$PACKAGE_NAME" \
        -C "$DIST_DIR" \
        --transform "s|^./||" \
        .

    info "打包完成: ${PACKAGE_PATH}"
    ls -lh "$PACKAGE_PATH"
}

# ─── 远程部署 ──────────────────────────────────────────────────────────────
remote_deploy() {
    if [[ "$SKIP_BUILD" != "true" ]]; then
        package
    else
        [[ -f "$PACKAGE_PATH" ]] || { error "部署包不存在: $PACKAGE_PATH"; exit 1; }
        info "使用已有部署包: $PACKAGE_PATH"
    fi

    info "开始部署到远程服务器 ${SSH_USER}@${SSH_HOST}:${SSH_PORT}..."

    # 测试 SSH 连接
    ssh -p "$SSH_PORT" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        "${SSH_USER}@${SSH_HOST}" "echo 'SSH 连接成功'" || {
        error "SSH 连接失败"
        exit 1
    }

    # 上传部署包
    info "上传部署包..."
    scp -P "$SSH_PORT" "$PACKAGE_PATH" "${SSH_USER}@${SSH_HOST}:/tmp/"

    # 远程执行安装
    info "在服务器上执行安装..."
    ssh -p "$SSH_PORT" "${SSH_USER}@${SSH_HOST}" "
        set -e
        INSTALL_DIR='${INSTALL_DIR}'

        # 创建安装目录并解压
        mkdir -p \"\$INSTALL_DIR\"
        tar -xzf /tmp/${PACKAGE_NAME} -C \"\$INSTALL_DIR\"

        # 执行安装脚本
        bash \"\$INSTALL_DIR/scripts/install.sh\"

        # 清理
        rm -f /tmp/${PACKAGE_NAME}
    "

    info "远程部署完成！"
    echo ""
    echo -e "  ${GREEN}访问地址: http://${SSH_HOST}:${PANEL_PORT}${NC}"
    [[ -n "$PANEL_ENTRY" ]] && echo -e "  ${GREEN}安全入口: ${PANEL_ENTRY}${NC}"
    echo -e "  ${YELLOW}默认账号: admin / admin123${NC}"
    echo ""
}

# ─── 本地安装（在服务器上直接使用） ────────────────────────────────────
local_install() {
    info "本地安装 UPanel..."

    # 检查 root
    [[ $EUID -eq 0 ]] || { error "安装需要 root 权限，请使用 sudo 或以 root 执行"; exit 1; }

    # 检查 Docker
    if ! command -v docker &>/dev/null; then
        warn "Docker 未安装，是否自动安装？[y/N]"
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            curl -fsSL https://get.docker.com | bash
            systemctl enable --now docker
        else
            error "UPanel 需要 Docker 环境"
            exit 1
        fi
    fi

    # 确定源目录
    if [[ -f "$PROJECT_DIR/bin/upanel" ]]; then
        # 从项目目录安装
        SRC_DIR="$PROJECT_DIR"
        mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/web" "$INSTALL_DIR/data"

        cp "$SRC_DIR/bin/upanel" "$INSTALL_DIR/bin/"
        cp "$SRC_DIR/bin/up" "$INSTALL_DIR/bin/" 2>/dev/null || true

        if [[ -d "$SRC_DIR/web/dist" ]]; then
            cp -r "$SRC_DIR/web/dist/"* "$INSTALL_DIR/web/"
        elif [[ -d "$SRC_DIR/web" ]]; then
            cp -r "$SRC_DIR/web/"* "$INSTALL_DIR/web/"
        fi

        # .env
        cat > "$INSTALL_DIR/.env" << EOF
PANEL_PORT=${PANEL_PORT}
JWT_SECRET=${JWT_SECRET}
PANEL_ENTRY=${PANEL_ENTRY}
EOF

    elif [[ -f "$SCRIPT_DIR/../bin/upanel" ]]; then
        # 从部署包结构安装
        SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
        mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/web" "$INSTALL_DIR/data"

        cp "$SRC_DIR/bin/upanel" "$INSTALL_DIR/bin/"
        cp "$SRC_DIR/bin/up" "$INSTALL_DIR/bin/" 2>/dev/null || true
        cp -r "$SRC_DIR/web/"* "$INSTALL_DIR/web/" 2>/dev/null || true
        cp "$SRC_DIR/.env" "$INSTALL_DIR/.env" 2>/dev/null || true
    else
        error "未找到编译产物，请先执行 ./scripts/deploy.sh pack"
        exit 1
    fi

    chmod +x "$INSTALL_DIR/bin/upanel" "$INSTALL_DIR/bin/up"

    # 注册 systemd 服务
    cat > /etc/systemd/system/upanel.service << SVCEOF
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
SVCEOF

    systemctl daemon-reload
    systemctl enable upanel
    systemctl restart upanel

    sleep 2
    if systemctl is-active --quiet upanel; then
        IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        echo ""
        info "╔══════════════════════════════════════════════════════════╗"
        info "║                   UPanel 安装完成！                     ║"
        info "╚══════════════════════════════════════════════════════════╝"
        echo ""
        info "  访问地址: http://${IP}:${PANEL_PORT}"
        [[ -n "$PANEL_ENTRY" ]] && info "  安全入口: ${PANEL_ENTRY}"
        echo ""
        info "  管理命令:"
        info "    systemctl status upanel    # 查看状态"
        info "    systemctl restart upanel   # 重启"
        info "    journalctl -u upanel -f    # 查看日志"
        echo ""
        echo -e "${YELLOW}  ⚠️  默认账号: admin / admin123${NC}"
        echo -e "${YELLOW}  ⚠️  首次登录后请立即修改密码！${NC}"
        echo ""
    else
        error "UPanel 启动失败，请检查日志: journalctl -u upanel -f"
        exit 1
    fi
}

# ─── 主流程 ────────────────────────────────────────────────────────────────
main() {
    print_banner
    parse_args "$@"

    case "$COMMAND" in
        pack)
            check_dependencies
            package
            info "部署包已生成: ${PACKAGE_PATH}"
            echo ""
            echo "  上传到服务器后执行:"
            echo "    tar -xzf ${PACKAGE_NAME} -C /opt/upanel"
            echo "    bash /opt/upanel/scripts/install.sh"
            echo ""
            echo "  或使用 deploy 命令一键部署:"
            echo "    $0 deploy --ssh-host <SERVER_IP> --secret '密钥' --entry 安全入口"
            ;;
        deploy)
            check_dependencies
            remote_deploy
            ;;
        install)
            local_install
            ;;
    esac
}

main "$@"
