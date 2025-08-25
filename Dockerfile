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
CMD ["sh", "-c", "echo '=== 启动调试信息 ===' && \
    php -m && \
    echo 'Swoole 状态:' && \
    php --ri swoole 2>&1 || echo 'Swoole 扩展未加载' && \
    echo '=== 尝试启动应用 ===' && \
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"]
