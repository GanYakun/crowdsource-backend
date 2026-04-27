# 多阶段构建：先编译，再打包运行镜像
FROM maven:3.9.15-eclipse-temurin-17 AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖（利用 Docker 缓存）
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源码并编译
COPY src ./src
RUN mvn clean package -DskipTests -B

# 运行阶段：使用轻量级 JRE 镜像
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 复制编译好的 jar
COPY --from=builder /app/target/crowdsource-backend-1.0.0.jar app.jar

# 暴露端口
EXPOSE 8080

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 启动应用
ENTRYPOINT ["java", "-jar", "-Xmx512m", "-Xms256m", "app.jar"]
