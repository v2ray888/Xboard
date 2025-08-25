FROM php:8.2-alpine

# 安装系统依赖
RUN apk update && apk add --no-cache \
    shadow \
    sqlite \
    mysql-client \
    mysql-dev \
    mariadb-connector-c \
    git \
    patch \
    supervisor \
    curl

# 安装 PHP 扩展（使用 docker-php-ext-install）
RUN docker-php-ext-install pcntl bcmath && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    apk del .build-deps

# 安装 Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 创建用户和组
RUN addgroup -S -g 1000 www && adduser -S -G www -u 1000 www

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 复制Supervisor配置
COPY .docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 修改Supervisor配置：使用PHP内置服务器
RUN sed -i 's|command=php /www/artisan swoole:http start|command=php artisan serve --host=0.0.0.0 --port=7001|' /etc/supervisor/conf.d/supervisord.conf

# 安装Composer依赖
RUN composer install --no-cache --no-dev --optimize-autoloader

# 设置存储目录权限
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache && \
    chown -R www:www /www && \
    chmod -R 775 storage bootstrap/cache && \
    php artisan storage:link

# 设置环境变量
ENV ENABLE_WEB=true \
    ENABLE_HORIZON=false \
    ENABLE_REDIS=false

EXPOSE 7001

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
