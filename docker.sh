#!/bin/bash

set -e


project_path=$(cd $(dirname $0); pwd -P)
project_docker_path="$project_path/docker"

developer_name=$('whoami')
app_basic_name="laravel"
app="$developer_name-$app_basic_name"

env=local

source $project_docker_path/bash.sh

source $project_docker_path/mysql/container.sh


help() {
cat <<EOF
    Usage: manage.sh [options]

        Valid options are:

        run
        stop
        restart
        clean
        clean_all

        run_mysql
        rm_mysql
        restart_mysql
        to_mysql

        help  show this message
EOF
}

ALL_COMMANDS="init clean clean_all new_egg download_code pull_code build_code_config run_mysql rm_mysql restart_mysql to_mysql delete_mysql "
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"

