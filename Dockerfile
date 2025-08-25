# 使用原项目指定的基础镜像
FROM phpswoole/swoole:php8.2-alpine

# 安装扩展安装工具
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

# ！！！关键修改：直接复制当前构建上下文的所有代码（由Koyeb自动拉取）
COPY . .

# 复制Supervisor配置
COPY .docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 安装Composer依赖并执行项目初始化
RUN composer install --no-cache --no-dev --optimize-autoloader \
    && php artisan storage:link \
    && chown -R www:www /www \
    && chmod -R 775 /www

# 设置环境变量（这些可以在Koyeb控制台覆盖）
ENV ENABLE_WEB=true \
    ENABLE_HORIZON=true \
    ENABLE_REDIS=false

# 暴露应用程序端口
EXPOSE 7001

# 启动应用
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
