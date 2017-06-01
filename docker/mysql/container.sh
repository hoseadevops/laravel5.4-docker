#!/bin/bash
set -e

mysql_image=mysql:5.7
mysql_container=$app-mysql5.7
project_docker_mysql_path="$project_docker_path/mysql"

mysql_data_dir="$project_docker_mysql_path/data"
mysql_data_init_dir="$project_docker_mysql_path/mysql-init"
mysql_data_append_dir="$project_docker_mysql_path/mysql-append"
mysql_conf_dir="$project_docker_mysql_path/conf/"
mysql_port="33062"

function run_mysql()
{
    local args="--restart always"
    # data
    args="$args -v $mysql_data_dir/mysql-data:/var/lib/mysql"

    # auto import data
    args="$args -v $mysql_data_init_dir:/docker-entrypoint-initdb.d/"

    # config
    args="$args -v $mysql_conf_dir:/etc/mysql/conf.d/"

    args="$args -v $project_path:$project_path"
    args="$args -w $project_path"

    # mysql port
    args="$args -p $mysql_port:3306"

    # do not use password
    args="$args -e MYSQL_ROOT_PASSWORD='' -e MYSQL_ALLOW_EMPTY_PASSWORD='yes'"
    run_cmd "docker run -d $args --name $mysql_container $mysql_image"

    _wait_mysql
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
    run_cmd "docker exec -i $(_open_tty) $mysql_container bash -c 'cd $project_path; $cmd'"
}

function _wait_mysql()
{
    local cmd="while ! mysqladmin ping -h 127.0.0.1 --silent; do sleep 1; done"
    _run_mysql_command_in_client "$cmd"
}