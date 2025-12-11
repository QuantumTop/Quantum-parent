# 使用亚马逊 OpenJDK 镜像作为基础镜像
FROM eclipse-temurin:25-jre-alpine-3.22

# 设置维护者信息
LABEL maintainer="Quantum Team"

# 接收构建参数
ARG AES_ENCRYPTION_KEY

# 设置环境变量
ENV AES_ENCRYPTION_KEY=${AES_ENCRYPTION_KEY}

# 设置工作目录
WORKDIR /app

# 复制 JAR 文件到容器中
COPY quantum-web/quantum-web-user/target/quantum-web-user-*.jar app.jar

# 暴露端口
EXPOSE 5001

# 运行应用程序
ENTRYPOINT ["java", "-jar", "app.jar"]