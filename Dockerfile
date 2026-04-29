# 多阶段构建
# 阶段1：Maven 编译
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# 先复制 pom.xml，利用 Docker 缓存加速依赖下载
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源码并编译
COPY src ./src
RUN mvn clean package -DskipTests -B

# 阶段2：运行时镜像
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# 从构建阶段复制 jar 包
COPY --from=builder /app/target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
