# 众包小程序后端 - Docker 部署指南

## 前置要求

服务器需要安装：
- Docker 20.10+
- Docker Compose 2.0+

## 快速部署

### 1. 上传项目到服务器

```bash
# 在本地打包项目（排除不必要的文件）
tar -czf crowdsource-backend.tar.gz \
  --exclude='target' \
  --exclude='.idea' \
  --exclude='*.log' \
  crowdsource-backend/

# 上传到服务器
scp crowdsource-backend.tar.gz user@your-server:/opt/

# SSH 登录服务器
ssh user@your-server

# 解压
cd /opt
tar -xzf crowdsource-backend.tar.gz
cd crowdsource-backend
```

### 2. 修改配置（可选）

编辑 `docker-compose.yml`，修改以下配置：

```yaml
# MySQL 密码
MYSQL_ROOT_PASSWORD: your-strong-password

# JWT 密钥（必须修改）
JWT_SECRET: your-production-secret-key-at-least-32-chars

# 端口映射（如果 8080 被占用）
ports:
  - "8888:8080"  # 改为其他端口
```

### 3. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看启动日志
docker-compose logs -f app

# 等待服务启动（约 30-60 秒）
```

### 4. 验证部署

```bash
# 测试接口
curl http://localhost:8080/api/tags

# 查看服务状态
docker-compose ps

# 查看应用日志
docker-compose logs app
```

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart app

# 查看日志
docker-compose logs -f app

# 进入容器
docker-compose exec app sh

# 进入 MySQL
docker-compose exec mysql mysql -uroot -p

# 重新构建并启动
docker-compose up -d --build

# 清理并重新部署（会删除数据）
docker-compose down -v
docker-compose up -d
```

## 数据备份

### 备份 MySQL 数据

```bash
# 导出数据库
docker-compose exec mysql mysqldump -uroot -p crowdsource > backup_$(date +%Y%m%d).sql

# 恢复数据库
docker-compose exec -T mysql mysql -uroot -p crowdsource < backup_20240422.sql
```

### 备份 Docker 卷

```bash
# 备份 MySQL 数据卷
docker run --rm \
  -v crowdsource-backend_mysql-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mysql-backup.tar.gz -C /data .
```

## 更新部署

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建镜像
docker-compose build app

# 3. 重启应用（不影响数据库）
docker-compose up -d app

# 4. 查看日志确认启动成功
docker-compose logs -f app
```

## 性能优化

### 调整 JVM 内存

编辑 `docker-compose.yml`：

```yaml
environment:
  JAVA_OPTS: -Xmx1g -Xms512m  # 根据服务器内存调整
```

### 调整 MySQL 配置

编辑 `docker-compose.yml`，添加 MySQL 配置：

```yaml
mysql:
  command:
    - --max_connections=200
    - --innodb_buffer_pool_size=256M
```

## 监控和日志

### 查看资源占用

```bash
docker stats crowdsource-app crowdsource-mysql
```

### 日志管理

```bash
# 限制日志大小（编辑 docker-compose.yml）
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 故障排查

### 应用无法启动

```bash
# 查看详细日志
docker-compose logs app

# 检查数据库连接
docker-compose exec app ping mysql

# 进入容器检查
docker-compose exec app sh
```

### 数据库连接失败

```bash
# 检查 MySQL 是否启动
docker-compose ps mysql

# 查看 MySQL 日志
docker-compose logs mysql

# 测试连接
docker-compose exec mysql mysql -uroot -p -e "SHOW DATABASES;"
```

### 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 8080

# 修改 docker-compose.yml 中的端口映射
ports:
  - "8888:8080"
```

## 安全建议

1. **修改默认密码**：修改 MySQL root 密码和 JWT 密钥
2. **配置防火墙**：只开放必要端口（如 8080）
3. **使用 HTTPS**：配置 Nginx 反向代理 + SSL 证书
4. **定期备份**：设置定时任务备份数据库
5. **日志监控**：配置日志收集和告警

## Nginx 反向代理配置（推荐）

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 联系支持

如有问题，请查看日志或联系技术支持。
