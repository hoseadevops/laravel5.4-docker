#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)                            # 项目目录
project_docker_path="$project_path/docker"                          # 项目docker目录
source $project_docker_path/bash.sh                                 # 基础函数
developer_name=$('whoami');                                         # 开发者

#----------------------
# 如果有配置中心 在这里创建 .env
#----------------------

app_basic_name=$(read_kv_config .env APP_NAME);                     # 项目名称 【英文表示】
app_env=$(read_kv_config .env APP_ENV);                             # app env laravel env: local testing production pre[后加 预生产]
mysql_port=$(read_kv_config .env DB_PORT);                          # 数据库端口号 【docker 映射外网端口】
nginx_port=$(read_kv_config .env NGINX_PORT);                       # nginx端口号 【docker 映射外网端口】

app="$developer_name-$app_basic_name"

busybox_image=hoseadevops/own-busybox
syslogng_image=hoseadevops/own-syslog-ng
redis_image=hoseadevops/own-redis:3.0.1
mysql_image=hoseadevops/own-mysql:5.7
php_image=hoseadevops/own-php:7.1.7-fpm
nginx_image=hoseadevops/own-nginx:1.11

# container
busybox_container=$app-busybox
syslogng_container=$app-syslog-ng
redis_container=$app-redis3.0.1
mysql_container=$app-mysql5.7
php_container=$app-php7.1.7
nginx_container_fpm=$app-nginx-fpm

# container dir
project_docker_busybox_path="$project_docker_path/busybox"
project_docker_syslogng_dir="$project_docker_path/syslog-ng"
project_docker_redis_dir="$project_docker_path/redis"
project_docker_mysql_path="$project_docker_path/mysql"
project_docker_php_dir="$project_docker_path/php"
project_docker_nginx_dir="$project_docker_path/nginx"
project_docker_runtime_dir="$project_docker_path/runtime"           # app runtime
project_docker_persistent_dir="$project_docker_path/persistent"     # app persistent

app_config="$project_docker_persistent_dir/config"

#---------- busybox container ------------#
source $project_docker_path/busybox/container.sh
#---------- syslog container ------------#
source $project_docker_path/syslog-ng/container.sh
#---------- redis container ------------#
source $project_docker_path/redis/container.sh
#---------- mysql container ------------#
source $project_docker_path/mysql/container.sh
#---------- php container ------------#
source $project_docker_path/php/container.sh
#---------- nginx container ------------#
source $project_docker_path/nginx/container.sh

function new_app()
{
    clean_all
    init_app
    run
}

function init_app()
{
    echo php_container=$php_container > $project_docker_persistent_dir/config
    echo php_fpm_port=9000 >> $project_docker_persistent_dir/config
    echo dk_nginx_domain=hosea.devops.com >> $project_docker_persistent_dir/config
    echo dk_nginx_root=$project_path/public >> $project_docker_persistent_dir/config
    echo open_basedir=$project_path:/tmp/:/proc/ >> $project_docker_persistent_dir/config

    recursive_mkdir "$project_docker_persistent_dir/nginx-fpm-config"
    recursive_mkdir "$project_docker_persistent_dir/mysql/data"

    run_cmd "replace_template_key_value $project_docker_persistent_dir/config $project_docker_nginx_dir/nginx-fpm-config-template/fastcgi $project_docker_persistent_dir/nginx-fpm-config/fastcgi"
    run_cmd "replace_template_key_value $project_docker_persistent_dir/config $project_docker_nginx_dir/nginx-fpm-config-template/hosea.conf $project_docker_persistent_dir/nginx-fpm-config/hosea.conf"
    run_cmd "replace_template_key_value $project_docker_persistent_dir/config $project_docker_php_dir/config-template/.user.ini $project_path/public/.user.ini"

    cat $project_docker_persistent_dir/config
    cat $project_docker_persistent_dir/nginx-fpm-config/hosea.conf
}

function run()
{
    run_syslogng
    run_busybox
    run_mysql
    run_redis
    run_php
    run_nginx_fpm
}

function clean()
{
    rm_syslogng
    rm_busybox
    rm_mysql
    rm_redis
    rm_php
    rm_nginx_fpm
    clean_runtime
}

function restart()
{
    clean
    run
}

function clean_all()
{
    clean
    clean_persistent
}

function clean_runtime()
{
    run_cmd "rm -rf $project_docker_runtime_dir/app"
    run_cmd "rm -rf $project_docker_runtime_dir/crontab"
    run_cmd "rm -rf $project_docker_runtime_dir/nginx-fpm"
    run_cmd "rm -rf $project_docker_runtime_dir/php"
    run_cmd "rm -rf $project_docker_runtime_dir/mysql"
    run_cmd "rm -rf $project_docker_runtime_dir/syslog-ng"
}

function clean_persistent()
{
    run_cmd "rm -f $project_docker_persistent_dir/config"
    run_cmd "rm -rf $project_docker_persistent_dir/mysql"
    run_cmd "rm -rf $project_docker_persistent_dir/nginx-fpm-config"
}

function help()
{
cat <<EOF
    Usage: sh docker.sh [options]

        Valid options are:

        new_app
        init_app
        run
        stop
        restart
        clean
        clean_all

        run_syslogng
        rm_syslogng
        restart_syslogng

        run_busybox
        rm_busybox

        run_mysql
        rm_mysql
        restart_mysql
        to_mysql

        run_redis
        to_redis
        rm_redis
        restart_redis

        build_php
        build_php_7

        run_php
        rm_php
        to_php

        _run_cmd_php_container

        run_nginx_fpm
        rm_nginx_fpm
        restart_nginx

        updateHost www.baidu.com 127.0.0.1

        read_kv_config .env DB_PORT

        push_image
        push_sunfund_image
        pull_sunfund_image

        help  show this message
EOF
}

action=${1:-help}
ALL_COMMANDS="new_app init_app restart push_image push_sunfund_image pull_sunfund_image read_kv_config updateHost run clean init clean_all new_egg download_code pull_code build_code_config run_nginx_fpm rm_nginx_fpm restart_nginx run_mysql rm_mysql restart_mysql to_mysql delete_mysql build_php run_php to_php rm_php _run_cmd_php_container run_redis to_redis rm_redis restart_redis rm_busybox run_busybox run_syslogng rm_syslogng restart_syslogng"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

