#!/bin/bash
set -e

function run_mysql()
{
    local mysql_data_dir="$project_docker_persistent_dir/mysql/data"
    local mysql_data_init_dir="$project_docker_mysql_path/mysql-init"
    local mysql_data_append_dir="$project_docker_mysql_path/mysql-append"
    local mysql_conf_dir="$project_docker_mysql_path/conf/"

    local mysql_log_dir="$project_docker_runtime_dir/mysql/"

    local args="--restart always"
    # data
    args="$args -v $mysql_data_dir/mysql-data:/var/lib/mysql"

    # auto import data
    args="$args -v $mysql_data_init_dir:/docker-entrypoint-initdb.d/"

    # config
    args="$args -v $mysql_conf_dir:/etc/mysql/conf.d/"
    # log
    args="$args -v $mysql_log_dir:/var/log/mysql/"

    args="$args -v $project_path:$project_path"
    args="$args -w $project_path"

    # mysql port
    args="$args -p $mysql_port:3306"

    # do not use password
    args="$args -e MYSQL_ROOT_PASSWORD='' -e MYSQL_ALLOW_EMPTY_PASSWORD='yes'"
    run_cmd "docker run -d $args --name $mysql_container $mysql_image"

    _wait_mysql
}

function _wait_mysql() {
    local cmd="while ! mysqladmin ping -h 127.0.0.1 --silent; do sleep 1; done"
    send_cmd_to_mysql_container "$cmd"
}

function rm_mysql()
{
    rm_container $mysql_container
}

function restart_mysql()
{
    rm_mysql
    run_mysql
}

function to_mysql()
{
    local cmd="mysql -h 127.0.0.1 -P 3306 -u root -p"
    _run_mysql_command_in_client "$cmd"
}


function _run_mysql_command_in_client()
{
    local cmd=$1
    run_cmd "docker exec -it $mysql_container bash -c 'cd $project_path; $cmd'"
}

function _wait_mysql()
{
    local cmd="while ! mysqladmin ping -h 127.0.0.1 --silent; do sleep 1; done"
    _run_mysql_command_in_client "$cmd"
}