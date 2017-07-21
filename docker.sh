#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)                    # 项目目录
project_docker_path="$project_path/docker"                  # 项目docker目录
source $project_docker_path/bash.sh                         # 基础函数
developer_name=$('whoami');                                 # 开发者

#----------------------
# 如果有配置中心 在这里创建 .env
#----------------------

app_basic_name=$(read_kv_config .env APP_NAME);             # 项目名称 【英文表示】
app_env=$(read_kv_config .env APP_ENV);                     # app env laravel env: local testing production pre[后加 预生产]

app="$developer_name-$app_basic_name"
project_docker_runtime_dir="$project_docker_path/runtime"   # app runtime

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

#---------- busybox container ------------#
source $project_docker_path/busybox/container.sh
#---------- syslog container ------------#
source $project_docker_path/syslog-ng/container.sh
#---------- redis container ------------#
source $project_docker_path/redis/container.sh
#---------- mysql container ------------#
mysql_port="33062"
source $project_docker_path/mysql/container.sh
#---------- php container ------------#
source $project_docker_path/php/container.sh
#---------- nginx container ------------#
source $project_docker_path/nginx/container.sh


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
}

function restart()
{
    clean
    run
}

function clean_all()
{
    clean
    run_cmd "rm -rf $project_docker_runtime_dir/app"
    run_cmd "rm -rf $project_docker_runtime_dir/crontab"
    run_cmd "rm -rf $project_docker_runtime_dir/nginx-fpm"
    run_cmd "rm -rf $project_docker_runtime_dir/php"
    run_cmd "rm -rf $project_docker_runtime_dir/syslog-ng"
}

help()
{
cat <<EOF
    Usage: sh docker.sh [options]

        Valid options are:

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

ALL_COMMANDS="restart push_image push_sunfund_image pull_sunfund_image read_kv_config updateHost run clean init clean clean_all new_egg download_code pull_code build_code_config run_nginx_fpm rm_nginx_fpm restart_nginx run_mysql rm_mysql restart_mysql to_mysql delete_mysql build_php run_php to_php rm_php _run_cmd_php_container run_redis to_redis rm_redis restart_redis rm_busybox run_busybox run_syslogng rm_syslogng restart_syslogng"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

