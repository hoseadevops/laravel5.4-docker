#dockerfile 一般分成四部分：基础镜像信息、维护者信息、镜像操作指令、容器启动时执行的指令
# this dockerfile uses the php image
# version
# Author：
#第一行 必须指定基于的基础镜像
FROM php:7.1.7-fpm

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ADD sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
        vim \
        libmemcached-dev \
        libmcrypt-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev \
        cron \
        rsyslog \
        && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install zip \
        && docker-php-ext-install gd \
        && docker-php-ext-install mbstring \
        && docker-php-ext-install mcrypt \
        && docker-php-ext-install sockets \
        && docker-php-ext-install opcache

RUN pecl install redis-3.1.3 && pecl install memcached-3.0.3
COPY .bashrc /root/

RUN curl -L https://phar.phpunit.de/phpunit-5.7.phar >> /tmp/phpunit.phar && mv /tmp/phpunit.phar /usr/local/bin/phpunit && chmod a+x /usr/local/bin/phpunit