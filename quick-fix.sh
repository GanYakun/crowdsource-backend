#!/bin/bash

# 快速修复脚本 - 重新构建并部署应用
# 使用方法: ./quick-fix.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}快速修复 - 重新构建应用${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 自动检测 docker compose 命令
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "未找到 Docker Compose"
    exit 1
fi

echo -e "${YELLOW}[1/4] 停止现有容器...${NC}"
$COMPOSE_CMD down

echo ""
echo -e "${YELLOW}[2/4] 重新构建应用镜像...${NC}"
$COMPOSE_CMD build app

echo ""
echo -e "${YELLOW}[3/4] 启动应用...${NC}"
$COMPOSE_CMD up -d

echo ""
echo -e "${YELLOW}[4/4] 等待应用启动...${NC}"
sleep 15

echo ""
echo -e "${GREEN}✓ 应用已重新部署${NC}"
echo ""
echo "测试访问:"
echo "  curl http://localhost:8080/api/tags"
echo ""
echo "查看日志:"
echo "  ./deploy.sh logs"
echo ""
echo -e "${BLUE}========================================${NC}"

