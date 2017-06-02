#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)
project_docker_path="$project_path/docker"

developer_name=$('whoami')
app_basic_name="laravel"
app="$developer_name-$app_basic_name"

#----------------------
# dev test prod
#----------------------

env=dev

source $project_docker_path/bash.sh

source $project_docker_path/busybox/container.sh

source $project_docker_path/mysql/container.sh

source $project_docker_path/redis/container.sh

#----------------------
# 依赖 busybox、redis
#----------------------
source $project_docker_path/php/container.sh

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


        help  show this message
EOF

}

ALL_COMMANDS="init clean clean_all new_egg download_code pull_code build_code_config run_mysql rm_mysql restart_mysql to_mysql delete_mysql build_php run_redis to_redis rm_redis restart_redis rm_busybox run_busybox"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

