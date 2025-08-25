FROM webdevops/php-apache:8.2-alpine

# 安装 MySQL 扩展
RUN docker-php-ext-install pdo pdo_mysql mysqli

# 设置工作目录
WORKDIR /www

# 先只复制 composer 文件（利用Docker缓存）
COPY composer.json composer.lock ./

# 安装 Composer 依赖
RUN composer install --no-cache --no-dev --optimize-autoloader --no-scripts

# 然后复制所有其他文件
COPY . .

# 设置存储目录权限
RUN chmod -R 775 storage bootstrap/cache

# 直接启动PHP服务器
CMD ["php", "-S", "0.0.0.0:7001", "-t", "public"]
