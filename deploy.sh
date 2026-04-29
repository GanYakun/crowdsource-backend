#!/bin/bash

# 众包小程序后端 - 一键部署脚本
# 使用方法: ./deploy.sh [start|stop|restart|logs|status|help]

set -e

PROJECT_NAME="crowdsource-backend"
COMPOSE_FILE="docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 自动检测 docker compose 命令
function get_compose_cmd() {
    if docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        log_error "未找到 Docker Compose，请安装："
        log_error "  sudo apt install docker-compose-plugin -y"
        exit 1
    fi
}

# 全局 compose 命令变量
COMPOSE_CMD=$(get_compose_cmd)

function check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    log_info "Docker 版本: $(docker --version)"
    log_info "Docker Compose 命令: $COMPOSE_CMD"
    log_info "Docker Compose 版本: $($COMPOSE_CMD version)"
}

function start_services() {
    log_info "启动服务..."
    $COMPOSE_CMD up -d

    log_info "等待服务启动..."
    sleep 15

    log_info "检查服务状态..."
    $COMPOSE_CMD ps

    log_info "服务启动完成！"
    log_info "访问地址: http://localhost:8080"
    log_info "查看日志: ./deploy.sh logs"
}

function stop_services() {
    log_info "停止服务..."
    $COMPOSE_CMD down
    log_info "服务已停止"
}

function restart_services() {
    log_info "重启容器（不重新构建镜像）..."
    log_warn "注意：此命令不会重新构建镜像，代码变更不会生效"
    log_warn "如果你更新了代码，请使用: ./deploy.sh update"
    $COMPOSE_CMD restart app
    log_info "容器已重启"
}

function update_app() {
    log_info "更新应用（重新构建镜像 + 重启容器）..."

    log_info "[1/3] 重新构建应用镜像..."
    $COMPOSE_CMD build app

    log_info "[2/3] 重启应用容器..."
    $COMPOSE_CMD up -d app

    log_info "[3/3] 等待应用启动..."
    sleep 15

    log_info "检查服务状态..."
    $COMPOSE_CMD ps

    log_info "应用更新完成！"
    log_info "查看日志: ./deploy.sh logs"
}

function show_logs() {
    log_info "显示应用日志（Ctrl+C 退出）..."
    $COMPOSE_CMD logs -f app
}

function show_status() {
    log_info "服务状态:"
    $COMPOSE_CMD ps

    echo ""
    log_info "资源占用:"
    docker stats --no-stream crowdsource-app mysql 2>/dev/null || true

    echo ""
    log_info "MySQL 容器信息:"
    docker ps --filter name=mysql --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
}

function show_help() {
    echo "众包小程序后端 - 部署脚本"
    echo ""
    echo "使用方法: ./deploy.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  start      - 启动所有服务（MySQL + 应用）"
    echo "  stop       - 停止所有服务"
    echo "  restart    - 重启应用容器（不重新构建，代码变更不生效）"
    echo "  update     - 重新构建镜像并重启（代码变更后使用此命令）"
    echo "  logs       - 查看应用日志"
    echo "  status     - 查看服务状态"
    echo "  help       - 显示帮助信息"
    echo ""
    echo "当前 Docker Compose 命令: $COMPOSE_CMD"
    echo ""
    echo "代码更新流程:"
    echo "  1. 上传新代码到服务器"
    echo "  2. ./deploy.sh update     # 重新构建并重启"
    echo "  3. ./deploy.sh logs       # 查看日志确认"
}

# 主逻辑
case "$1" in
    start)
        check_docker
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    update)
        update_app
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
