#!/bin/bash

# 使用阿里云云效制品 package.tgz 部署
# 制品路径: /home/admin/app/package.tgz

set -e

SERVER_IP="8.138.32.1"
PROJECT_DIR="/opt/crowdsource-backend"
ARTIFACT_PATH="/home/admin/app/package.tgz"

echo "使用阿里云云效制品部署..."
echo "制品路径: ${ARTIFACT_PATH}"

# 在服务器上部署
ssh root@${SERVER_IP} << 'EOF'
cd ${PROJECT_DIR}

# 1. 检查制品是否存在
if [ ! -f "${ARTIFACT_PATH}" ]; then
    echo "❌ 制品不存在: ${ARTIFACT_PATH}"
    echo "请确认流水线构建步骤已生成制品"
    exit 1
fi

echo "✅ 找到制品: $(ls -lh ${ARTIFACT_PATH})"

# 2. 备份当前代码
if [ -d "src" ]; then
    BACKUP_FILE="backup-$(date +%Y%m%d%H%M%S).tar.gz"
    tar -czf ${BACKUP_FILE} src/ target/ 2>/dev/null || true
    echo "备份当前代码: ${BACKUP_FILE}"
fi

# 3. 复制制品到项目目录
echo "复制制品..."
cp ${ARTIFACT_PATH} package.tgz

# 4. 解压制品
echo "解压制品..."
tar -xzf package.tgz

# 5. 验证制品内容
echo "制品内容:"
ls -la target/*.jar 2>/dev/null || echo "警告: target 目录没有 jar 包"

# 6. 停止旧容器
echo "停止旧容器..."
docker compose down 2>/dev/null || true

# 7. 重新构建镜像（使用制品中的 jar 包）
echo "构建 Docker 镜像..."
docker compose build app

# 8. 启动容器
echo "启动容器..."
docker compose up -d

# 9. 等待启动
sleep 10

# 10. 验证部署
if curl -s http://localhost:8080/api/tags | grep -q "success"; then
    echo "✅ 部署成功"
else
    echo "❌ 部署失败"
    exit 1
fi
EOF

echo "部署完成！"
echo "访问地址: http://${SERVER_IP}:8080/api/tags"
