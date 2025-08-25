FROM php:8.2-alpine

# 安装系统依赖
RUN apk update && apk add --no-cache \
    shadow \
    sqlite \
    mysql-client \
    mysql-dev \
    mariadb-connector-c \
    git \
    curl \
    supervisor

# 安装 PHP 扩展
RUN docker-php-ext-install pcntl bcmath pdo pdo_mysql mysqli

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 创建用户和组
RUN addgroup -S -g 1000 www && adduser -S -G www -u 1000 www

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 安装Composer依赖
RUN composer install --no-cache --no-dev --optimize-autoloader

# 设置存储目录权限
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache && \
    chown -R www:www /www && \
    chmod -R 775 storage bootstrap/cache

# 初始化数据库（创建数据表）
RUN php artisan migrate --force

# 直接启动PHP服务器
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=7001"]
