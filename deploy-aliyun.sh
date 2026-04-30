#!/bin/bash

# 阿里云流水线部署脚本
# 在流水线的"执行命令"步骤中使用

set -e

SERVER_IP="8.138.32.1"
PROJECT_DIR="/opt/crowdsource-backend"

echo "开始部署到阿里云服务器..."

# 1. 上传文件到服务器
echo "上传文件到服务器..."
scp -r ./* root@${SERVER_IP}:${PROJECT_DIR}/

# 2. 在服务器上执行部署
echo "在服务器上执行部署..."
ssh root@${SERVER_IP} << 'EOF'
cd /opt/crowdsource-backend

# 确保文件权限
chmod +x deploy.sh

# 停止旧容器
docker compose down 2>/dev/null || true

# 重新构建并启动
docker compose build app
docker compose up -d

# 等待启动
sleep 10

# 验证部署
curl -s http://localhost:8080/api/tags | grep -q "success" && echo "部署成功" || echo "部署失败"
EOF

echo "部署完成！"
echo "访问地址: http://${SERVER_IP}:8080/api/tags"
