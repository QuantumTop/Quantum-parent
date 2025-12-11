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

# 复制所有 JAR 文件到容器中
COPY quantum-gateway/target/quantum-gateway-*.jar gateway.jar
COPY quantum-web/quantum-web-user/target/quantum-web-user-*.jar user.jar

# 创建启动脚本
RUN echo '#!/bin/bash\n\
if [ "$SERVICE_NAME" = "gateway" ]; then\n\
  java -jar gateway.jar\n\
elif [ "$SERVICE_NAME" = "user" ]; then\n\
  java -jar user.jar\n\
else\n\
  echo "请设置 SERVICE_NAME 环境变量为 '\''gateway'\'' 或 '\''user'\''"\n\
  exit 1\n\
fi' > run.sh && chmod +x run.sh

# 根据环境变量暴露端口
EXPOSE 5000 5001

# 运行应用程序
ENTRYPOINT ["./run.sh"]