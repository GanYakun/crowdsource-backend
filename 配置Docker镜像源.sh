#!/bin/bash

# 配置 Docker 国内镜像源
# 使用方法: sudo ./配置Docker镜像源.sh

set -e

echo "配置 Docker 国内镜像源..."

# 创建 Docker 配置目录
sudo mkdir -p /etc/docker

# 备份原配置（如果存在）
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "已备份原配置文件"
fi

# 写入镜像源配置
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://docker.chenby.cn",
    "https://dockerpull.org"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "镜像源配置完成"

# 重启 Docker 服务
echo "重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Docker 服务已重启"

# 验证配置
echo ""
echo "验证配置:"
sudo docker info | grep -A 5 "Registry Mirrors"

echo ""
echo "配置完成！现在可以重新运行部署脚本"
