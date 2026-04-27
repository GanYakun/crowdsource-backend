# 众包小程序后端系统

基于 Spring Boot 3.2 + MyBatis-Plus 的众包任务管理系统后端。

## 功能特性

### 用户系统
- 微信登录 / 手机号登录
- 三种角色：管理员、发单人、接单人
- 用户资料管理（技术栈、标签、接单偏好）

### 任务系统
- 任务发布与管理
- 任务状态流转（待审核 → 招募中 → 进行中 → 已完成）
- 技术标签系统
- 任务搜索与筛选

### 接单/撮合系统
- 接单申请
- 智能任务推荐（按技术栈和预算匹配）
- 申请处理

### 通知系统
- 新任务通知
- 匹配提醒
- 接单结果通知

### 管理后台
- 任务审核
- 用户管理
- 任务下架

## 技术栈

- **框架**: Spring Boot 3.2.5
- **ORM**: MyBatis-Plus 3.5.7
- **数据库**: MySQL 8.0
- **缓存**: Redis 7（可选）
- **认证**: JWT
- **构建**: Maven 3.9+
- **JDK**: 17

## 快速开始

### 本地开发

#### 前置要求
- JDK 17+
- Maven 3.9+
- MySQL 8.0+
- Redis（可选）

#### 启动步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd crowdsource-backend
```

2. **配置数据库**
```bash
# 创建数据库
mysql -uroot -p < src/main/resources/db/schema.sql
```

3. **修改配置**
编辑 `src/main/resources/application.yml`：
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/crowdsource
    username: root
    password: your-password

jwt:
  secret: your-secret-key
```

4. **编译运行**
```bash
mvn clean package -DskipTests
java -jar target/crowdsource-backend-1.0.0.jar
```

5. **访问接口**
```bash
curl http://localhost:8080/api/tags
```

### Docker 部署

#### 快速部署（推荐）

```bash
# 1. 启动所有服务
./deploy.sh start

# 2. 查看日志
./deploy.sh logs

# 3. 查看状态
./deploy.sh status
```

#### 手动部署

```bash
# 1. 启动服务
docker-compose up -d

# 2. 查看日志
docker-compose logs -f app

# 3. 停止服务
docker-compose down
```

详细部署文档请查看 [DEPLOY.md](DEPLOY.md)

## API 文档

### 认证接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/auth/login` | POST | 用户登录（微信/手机号） |
| `/api/auth/sms/send` | POST | 发送短信验证码 |

### 用户接口

| 接口 | 方法 | 说明 | 需要认证 |
|------|------|------|----------|
| `/api/user/me` | GET | 获取当前用户信息 | ✓ |
| `/api/user/profile` | PUT | 更新用户资料 | ✓ |

### 任务接口

| 接口 | 方法 | 说明 | 需要认证 |
|------|------|------|----------|
| `/api/tasks` | POST | 发布任务 | ✓ |
| `/api/tasks` | GET | 任务列表（支持筛选） | ✓ |
| `/api/tasks/{id}` | GET | 任务详情 | ✓ |
| `/api/tasks/recommend` | GET | 推荐任务 | ✓ |
| `/api/tasks/{id}/apply` | POST | 申请接单 | ✓ |
| `/api/tasks/applications/{id}/handle` | POST | 处理申请 | ✓ |
| `/api/tasks/{id}/complete` | POST | 标记完成 | ✓ |

### 标签接口

| 接口 | 方法 | 说明 | 需要认证 |
|------|------|------|----------|
| `/api/tags` | GET | 获取所有标签 | ✗ |

### 通知接口

| 接口 | 方法 | 说明 | 需要认证 |
|------|------|------|----------|
| `/api/notifications` | GET | 通知列表 | ✓ |
| `/api/notifications/unread-count` | GET | 未读数量 | ✓ |
| `/api/notifications/read` | PUT | 标记已读 | ✓ |

### 管理后台接口

| 接口 | 方法 | 说明 | 需要认证 |
|------|------|------|----------|
| `/api/admin/tasks` | GET | 任务列表 | ✓（管理员） |
| `/api/admin/tasks/{id}/review` | POST | 审核任务 | ✓（管理员） |
| `/api/admin/tasks/{id}/offline` | POST | 下架任务 | ✓（管理员） |
| `/api/admin/users` | GET | 用户列表 | ✓（管理员） |
| `/api/admin/users/{id}/status` | PUT | 启用/禁用用户 | ✓（管理员） |

## 项目结构

```
crowdsource-backend/
├── src/main/java/com/crowdsource/
│   ├── config/          # 配置类（JWT、拦截器、MyBatis）
│   ├── controller/      # 控制器层
│   ├── service/         # 业务逻辑层
│   ├── mapper/          # 数据访问层
│   ├── entity/          # 实体类
│   ├── dto/             # 数据传输对象
│   ├── enums/           # 枚举类
│   └── common/          # 通用工具类
├── src/main/resources/
│   ├── mapper/          # MyBatis XML 映射文件
│   ├── db/              # 数据库脚本
│   └── application.yml  # 应用配置
├── Dockerfile           # Docker 镜像构建文件
├── docker-compose.yml   # Docker Compose 配置
├── deploy.sh            # 一键部署脚本
└── DEPLOY.md            # 部署文档
```

## 数据库设计

### 核心表

- `user` - 用户表
- `user_profile` - 用户详情表
- `task` - 任务表
- `task_tag` - 任务标签关联表
- `tag` - 标签表
- `task_application` - 接单申请表
- `notification` - 通知表

详细表结构请查看 `src/main/resources/db/schema.sql`

## 开发指南

### 添加新接口

1. 在 `entity` 包创建实体类
2. 在 `mapper` 包创建 Mapper 接口
3. 在 `service` 包实现业务逻辑
4. 在 `controller` 包创建控制器
5. 在 `WebConfig` 中配置拦截器规则（如需认证）

### 运行测试

```bash
# Windows PowerShell
./test-api.ps1

# Linux/Mac
# 需要先转换为 bash 脚本或使用 curl 测试
```

## 常见问题

### 1. 启动失败：端口被占用
```bash
# 修改 application.yml 中的端口
server:
  port: 8888
```

### 2. 数据库连接失败
- 检查 MySQL 是否启动
- 检查数据库用户名密码
- 检查数据库是否已创建

### 3. JWT token 无效
- 检查 JWT 密钥配置
- 检查 token 是否过期
- 检查 Authorization header 格式：`Bearer <token>`

## 生产环境建议

1. **修改默认密码**
   - MySQL root 密码
   - JWT 密钥（至少 32 位）

2. **配置 HTTPS**
   - 使用 Nginx 反向代理
   - 配置 SSL 证书

3. **性能优化**
   - 调整 JVM 内存参数
   - 配置数据库连接池
   - 启用 Redis 缓存

4. **监控告警**
   - 配置日志收集
   - 设置资源监控
   - 配置异常告警

5. **定期备份**
   - 数据库定时备份
   - 日志归档

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交 Issue 或 Pull Request。
