#!/bin/bash

# 在现有 MySQL 容器中初始化 crowdsource_db 数据库
# 使用方法: ./init-database.sh

set -e

MYSQL_CONTAINER="mysql"
MYSQL_USER="cs_user"
MYSQL_PASSWORD="Ganyakun0506,"
MYSQL_DATABASE="crowdsource_db"
SQL_FILE="./src/main/resources/db/schema.sql"

echo "=========================================="
echo "众包小程序后端 - 数据库初始化脚本"
echo "=========================================="
echo ""

# 检查 MySQL 容器是否运行
if ! docker ps | grep -q "$MYSQL_CONTAINER"; then
    echo "错误: MySQL 容器 '$MYSQL_CONTAINER' 未运行"
    echo "请先启动 MySQL 容器"
    exit 1
fi

echo "✓ MySQL 容器运行正常"

# 检查 SQL 文件是否存在
if [ ! -f "$SQL_FILE" ]; then
    echo "错误: SQL 文件不存在: $SQL_FILE"
    exit 1
fi

echo "✓ SQL 文件存在"
echo ""

# 检查数据库是否存在
echo "检查数据库 '$MYSQL_DATABASE' 是否存在..."
DB_EXISTS=$(docker exec $MYSQL_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" -e "SHOW DATABASES LIKE '$MYSQL_DATABASE';" 2>/dev/null | grep -c "$MYSQL_DATABASE" || true)

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "数据库不存在，正在创建..."
    docker exec $MYSQL_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    echo "✓ 数据库创建成功"
else
    echo "✓ 数据库已存在"
fi

echo ""
echo "开始导入表结构和初始数据..."

# 导入 SQL 文件
docker exec -i $MYSQL_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE < $SQL_FILE

if [ $? -eq 0 ]; then
    echo "✓ 数据库初始化成功！"
    echo ""
    echo "验证表结构..."
    docker exec $MYSQL_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE -e "SHOW TABLES;"
    echo ""
    echo "检查初始数据（标签表）..."
    docker exec $MYSQL_CONTAINER mysql -u$MYSQL_USER -p"$MYSQL_PASSWORD" $MYSQL_DATABASE -e "SELECT COUNT(*) as tag_count FROM tag;"
else
    echo "✗ 数据库初始化失败"
    exit 1
fi

echo ""
echo "=========================================="
echo "初始化完成！"
echo "=========================================="
echo "数据库名: $MYSQL_DATABASE"
echo "用户名: $MYSQL_USER"
echo "现在可以启动应用: ./deploy.sh start"
