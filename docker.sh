#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)

project_docker_path="$project_path/docker"

source $project_docker_path/bash.sh

developer_name=$('whoami');

app_basic_name=$(read_kv_config .env APP_NAME);
#----------------------
# laravel env: local testing production pre[后加 预生产]
#----------------------
app_env=$(read_kv_config .env APP_ENV);

app="$developer_name-$app_basic_name"

source $project_docker_path/busybox/container.sh

source $project_docker_path/syslog-ng/container.sh

source $project_docker_path/redis/container.sh

source $project_docker_path/mysql/container.sh

source $project_docker_path/php/container.sh

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

ALL_COMMANDS="build_php_7 push_image push_sunfund_image pull_sunfund_image read_kv_config updateHost run clean init clean clean_all new_egg download_code pull_code build_code_config run_nginx_fpm rm_nginx_fpm restart_nginx run_mysql rm_mysql restart_mysql to_mysql delete_mysql build_php run_php to_php rm_php _run_cmd_php_container run_redis to_redis rm_redis restart_redis rm_busybox run_busybox run_syslogng rm_syslogng restart_syslogng"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

