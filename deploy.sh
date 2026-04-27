#!/bin/bash

# 众包小程序后端 - 一键部署脚本
# 使用方法: ./deploy.sh [start|stop|restart|logs|status|backup]

set -e

PROJECT_NAME="crowdsource-backend"
COMPOSE_FILE="docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_info "Docker 环境检查通过"
}

function start_services() {
    log_info "启动服务..."
    docker-compose up -d
    
    log_info "等待服务启动..."
    sleep 10
    
    log_info "检查服务状态..."
    docker-compose ps
    
    log_info "服务启动完成！"
    log_info "访问地址: http://localhost:8080"
    log_info "查看日志: docker-compose logs -f app"
}

function stop_services() {
    log_info "停止服务..."
    docker-compose down
    log_info "服务已停止"
}

function restart_services() {
    log_info "重启服务..."
    docker-compose restart
    log_info "服务已重启"
}

function show_logs() {
    log_info "显示应用日志（Ctrl+C 退出）..."
    docker-compose logs -f app
}

function show_status() {
    log_info "服务状态:"
    docker-compose ps
    
    echo ""
    log_info "资源占用:"
    docker stats --no-stream crowdsource-app crowdsource-mysql crowdsource-redis 2>/dev/null || true
}

function backup_database() {
    BACKUP_DIR="./backups"
    mkdir -p $BACKUP_DIR
    
    BACKUP_FILE="$BACKUP_DIR/crowdsource_$(date +%Y%m%d_%H%M%S).sql"
    
    log_info "备份数据库到: $BACKUP_FILE"
    docker-compose exec -T mysql mysqldump -uroot -p\${MYSQL_ROOT_PASSWORD} crowdsource > $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        log_info "数据库备份成功: $BACKUP_FILE"
        
        # 压缩备份文件
        gzip $BACKUP_FILE
        log_info "备份文件已压缩: ${BACKUP_FILE}.gz"
    else
        log_error "数据库备份失败"
        exit 1
    fi
}

function update_app() {
    log_info "更新应用..."
    
    # 重新构建镜像
    log_info "重新构建应用镜像..."
    docker-compose build app
    
    # 重启应用容器
    log_info "重启应用容器..."
    docker-compose up -d app
    
    log_info "应用更新完成"
    show_logs
}

function init_check() {
    log_info "初始化检查..."
    
    # 检查配置文件
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "找不到 $COMPOSE_FILE 文件"
        exit 1
    fi
    
    # 检查 JWT 密钥是否修改
    if grep -q "your-production-secret-key-change-this-in-production" $COMPOSE_FILE; then
        log_warn "检测到默认 JWT 密钥，建议修改 docker-compose.yml 中的 JWT_SECRET"
    fi
    
    # 检查 MySQL 密码是否修改
    if grep -q "crowdsource_root_2024" $COMPOSE_FILE; then
        log_warn "检测到默认 MySQL 密码，建议修改 docker-compose.yml 中的 MYSQL_ROOT_PASSWORD"
    fi
}

function show_help() {
    echo "众包小程序后端 - 部署脚本"
    echo ""
    echo "使用方法: ./deploy.sh [命令]"
    echo ""
    echo "可用命令:"
    echo "  start      - 启动所有服务"
    echo "  stop       - 停止所有服务"
    echo "  restart    - 重启所有服务"
    echo "  logs       - 查看应用日志"
    echo "  status     - 查看服务状态"
    echo "  backup     - 备份数据库"
    echo "  update     - 更新应用（重新构建并重启）"
    echo "  help       - 显示帮助信息"
    echo ""
    echo "示例:"
    echo "  ./deploy.sh start    # 启动服务"
    echo "  ./deploy.sh logs     # 查看日志"
    echo "  ./deploy.sh backup   # 备份数据库"
}

# 主逻辑
case "$1" in
    start)
        check_docker
        init_check
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    backup)
        backup_database
        ;;
    update)
        check_docker
        update_app
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
