FROM php:8.2-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# 安装系统依赖和PHP扩展
RUN CFLAGS="-O0" install-php-extensions pcntl && \
    CFLAGS="-O0 -g0" install-php-extensions bcmath && \
    install-php-extensions zip && \
    install-php-extensions redis && \
    apk --no-cache add shadow sqlite mysql-client mysql-dev mariadb-connector-c git patch supervisor && \
    addgroup -S -g 1000 www && adduser -S -G www -u 1000 www

# 设置工作目录
WORKDIR /www

# 复制代码
COPY . .

# 复制Supervisor配置
COPY .docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 修改Supervisor配置：使用PHP内置服务器而不是Swoole
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
