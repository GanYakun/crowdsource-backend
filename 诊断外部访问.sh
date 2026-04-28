#!/bin/bash

# 诊断外部访问问题
# 使用方法: ./诊断外部访问.sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}诊断外部访问问题${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 检查应用容器状态
echo -e "${BLUE}[1/7] 检查应用容器状态${NC}"
if docker ps | grep -q "crowdsource-app"; then
    echo -e "${GREEN}✓ 应用容器运行中${NC}"
    docker ps --filter name=crowdsource-app --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo -e "${RED}✗ 应用容器未运行${NC}"
    echo "请先启动: ./deploy.sh start"
    exit 1
fi
echo ""

# 2. 检查容器内部服务
echo -e "${BLUE}[2/7] 检查容器内部服务${NC}"
INTERNAL_CHECK=$(docker exec crowdsource-app wget -q -O- http://localhost:8080/api/tags 2>&1 || echo "failed")
if echo "$INTERNAL_CHECK" | grep -q "success"; then
    echo -e "${GREEN}✓ 容器内部服务正常${NC}"
else
    echo -e "${RED}✗ 容器内部服务异常${NC}"
    echo "查看日志: ./deploy.sh logs"
    exit 1
fi
echo ""

# 3. 检查服务器本地访问
echo -e "${BLUE}[3/7] 检查服务器本地访问${NC}"
LOCAL_CHECK=$(curl -s http://localhost:8080/api/tags 2>&1 || echo "failed")
if echo "$LOCAL_CHECK" | grep -q "success"; then
    echo -e "${GREEN}✓ 服务器本地可以访问${NC}"
else
    echo -e "${RED}✗ 服务器本地无法访问${NC}"
    echo "可能是端口映射问题"
fi
echo ""

# 4. 检查端口监听
echo -e "${BLUE}[4/7] 检查端口监听${NC}"
if netstat -tlnp 2>/dev/null | grep -q ":8080"; then
    echo -e "${GREEN}✓ 8080 端口正在监听${NC}"
    netstat -tlnp 2>/dev/null | grep ":8080"
elif ss -tlnp 2>/dev/null | grep -q ":8080"; then
    echo -e "${GREEN}✓ 8080 端口正在监听${NC}"
    ss -tlnp 2>/dev/null | grep ":8080"
else
    echo -e "${RED}✗ 8080 端口未监听${NC}"
    echo "检查 docker-compose.yml 中的端口映射"
fi
echo ""

# 5. 检查防火墙（iptables）
echo -e "${BLUE}[5/7] 检查防火墙规则${NC}"
if command -v iptables &> /dev/null; then
    if sudo iptables -L -n | grep -q "8080"; then
        echo -e "${YELLOW}⚠ 发现 8080 端口的防火墙规则${NC}"
        sudo iptables -L -n | grep "8080"
    else
        echo -e "${GREEN}✓ 未发现阻止 8080 的规则${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 未安装 iptables${NC}"
fi
echo ""

# 6. 检查 UFW 防火墙
echo -e "${BLUE}[6/7] 检查 UFW 防火墙${NC}"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>&1 || echo "inactive")
    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        echo -e "${YELLOW}⚠ UFW 防火墙已启用${NC}"
        if echo "$UFW_STATUS" | grep -q "8080"; then
            echo -e "${GREEN}✓ 8080 端口已开放${NC}"
        else
            echo -e "${RED}✗ 8080 端口未开放${NC}"
            echo "运行以下命令开放端口:"
            echo "  sudo ufw allow 8080/tcp"
        fi
        sudo ufw status | grep -E "8080|Status"
    else
        echo -e "${GREEN}✓ UFW 防火墙未启用${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 未安装 UFW${NC}"
fi
echo ""

# 7. 获取服务器 IP
echo -e "${BLUE}[7/7] 服务器网络信息${NC}"
echo "服务器 IP 地址:"
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print "  " $2}' || \
    ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print "  " $2}'
echo ""

# 总结和建议
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}诊断总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 获取公网 IP（如果可能）
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "无法获取")
echo "服务器公网 IP: $PUBLIC_IP"
echo ""

echo "测试访问:"
echo "  内网: curl http://localhost:8080/api/tags"
if [ "$PUBLIC_IP" != "无法获取" ]; then
    echo "  外网: curl http://$PUBLIC_IP:8080/api/tags"
fi
echo ""

echo -e "${YELLOW}如果外部仍无法访问，请检查:${NC}"
echo "  1. 阿里云安全组是否开放 8080 端口"
echo "  2. 服务器防火墙是否开放 8080 端口"
echo "  3. Docker 容器是否正确映射端口"
echo ""

echo "快速解决方案:"
echo "  开放防火墙: sudo ufw allow 8080/tcp"
echo "  或禁用防火墙: sudo ufw disable"
echo "  查看日志: ./deploy.sh logs"
echo ""
echo -e "${BLUE}========================================${NC}"
