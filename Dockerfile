FROM php:8.2-alpine

# 安装最基本依赖
RUN apk update && apk add --no-cache curl git

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 安装依赖（但不运行任何可能失败的命令）
RUN composer install --no-cache --no-dev --optimize-autoloader

# 只设置基本权限
RUN chmod -R 775 storage bootstrap/cache

# 最简单的启动命令
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=7001"]
