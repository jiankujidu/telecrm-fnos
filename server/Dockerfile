# 后端 Dockerfile（多阶段构建）
# 构建上下文为 ./server

# 阶段 1：Maven 打包（使用阿里云镜像加速依赖下载）
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# 配置阿里云 Maven 镜像，避免访问中央仓库过慢
RUN mkdir -p /root/.m2 && \
    printf '%s\n' \
    '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">' \
    '  <mirrors>' \
    '    <mirror>' \
    '      <id>aliyun-central</id>' \
    '      <name>aliyun maven</name>' \
    '      <url>https://maven.aliyun.com/repository/public</url>' \
    '      <mirrorOf>central</mirrorOf>' \
    '    </mirror>' \
    '  </mirrors>' \
    '</settings>' > /root/.m2/settings.xml

# 先只拷 pom，利用 Docker 缓存：pom 不变时不重复下载依赖
COPY pom.xml .
RUN mvn -B dependency:go-offline || true

COPY src ./src
RUN mvn -B clean package -DskipTests

# 阶段 2：运行（仅 JRE，镜像体积更小）
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/tele-sales-crm-server-1.0.0.jar /app/app.jar

# 录音 / 导入文件存储目录（对应 application.yml 的 telecrm.storage.path）
RUN mkdir -p /app/uploads
ENV TZ=Asia/Shanghai
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "-Duser.timezone=Asia/Shanghai", "/app/app.jar"]
