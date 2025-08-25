FROM phpswoole/swoole:php8.2-alpine

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

# 安装Composer依赖
RUN composer install --no-cache --no-dev --optimize-autoloader

# 调试：检查Swoole扩展
RUN echo "=== 检查Swoole扩展 ===" && \
    php -m | grep swoole && \
    php --ri swoole

# 设置存储目录权限
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache && \
    chown -R www:www /www && \
    chmod -R 775 storage bootstrap/cache

# 设置环境变量
ENV ENABLE_WEB=true \
    ENABLE_HORIZON=false \
    ENABLE_REDIS=false

# 暴露端口
EXPOSE 7001

# 使用调试启动命令
# 替换最后的 CMD 行
CMD ["sh", "-c", "echo '=== 启动应用并捕获输出 ===' && \
    # 直接运行命令并捕获输出，而不是通过Supervisor
    php artisan swoole:http start 2>&1 || \
    (echo '=== 命令失败，显示最后50行日志 ===' && \
    tail -n 50 /www/storage/logs/laravel.log 2>/dev/null || echo '无日志文件')"]
