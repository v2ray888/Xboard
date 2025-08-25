FROM webdevops/php-apache:8.2-alpine

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 直接启动PHP服务器（完全跳过composer install）
CMD ["php", "-S", "0.0.0.0:7001", "-t", "public"]
