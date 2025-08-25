FROM webdevops/php-apache:8.2-alpine

# 安装 MySQL 扩展和其他必要扩展
RUN docker-php-ext-install pdo pdo_mysql mysqli

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 直接启动PHP服务器
CMD ["php", "-S", "0.0.0.0:7001", "-t", "public"]
