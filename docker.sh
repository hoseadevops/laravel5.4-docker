#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)

project_docker_path="$project_path/docker"

source $project_docker_path/bash.sh

developer_name=$('whoami');

app_basic_name=$(read_kv_config .env APP_NAME);
#----------------------
# laravel: local testing production pre[后加 预生产]
#----------------------
app_env=$(read_kv_config .env APP_ENV);

app="$developer_name-$app_basic_name"

source $project_docker_path/busybox/container.sh

source $project_docker_path/syslog-ng/container.sh

source $project_docker_path/redis/container.sh

source $project_docker_path/mysql/container.sh

source $project_docker_path/php/container.sh

source $project_docker_path/nginx/container.sh

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
        run_php
        rm_php
        to_php
        _run_cmd_php_container

        run_nginx_fpm
        rm_nginx
        restart_nginx

        updateHost www.baidu.com 127.0.0.1

        read_kv_config .env DB_PORT

        push_image
        pull_sunfund_image

        help  show this message
EOF
}

ALL_COMMANDS="push_sunfund_image pull_sunfund_image read_kv_config updateHost init clean clean_all new_egg download_code pull_code build_code_config run_nginx_fpm rm_nginx restart_nginx run_mysql rm_mysql restart_mysql to_mysql delete_mysql build_php run_php to_php rm_php _run_cmd_php_container run_redis to_redis rm_redis restart_redis rm_busybox run_busybox run_syslogng rm_syslogng restart_syslogng"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

