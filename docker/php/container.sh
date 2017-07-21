#!/bin/bash
set -e

php_image=hoseadevops/sunfund-9dy-php:5.6.8-fpm
php_image_7=hoseadevops/own-php_image_7

php_container=$app-php5.6
php_container_7=$app-php7.1.7

project_docker_php_dir="$project_docker_path/php"
project_docker_runtime_dir="$project_docker_path/runtime"
project_docker_php_image_dir="$project_docker_path/php/image5.6.8"
project_docker_php_image_dir_7="$project_docker_path/php/image7.1.7"

function build_php()
{
    docker build -t $php_image $project_docker_php_image_dir
}

function build_php_7()
{
    docker build -t  php_image_7 $project_docker_php_image_dir_7
}


function run_php()
{
    local args='--restart=always'

    args="$args --cap-add SYS_PTRACE"

    args="$args -v $project_docker_runtime_dir/php:/var/log/php"

    args="$args -v $project_docker_runtime_dir/crontab:/var/log/crontab"

    if [ "$app_env" = 'local' ]; then
        args="$args -v $project_docker_php_dir/conf/php-dev.ini:/usr/local/etc/php/php.ini"
    else
        args="$args -v $project_docker_php_dir/conf/php-prod.ini:/usr/local/etc/php/php.ini"
    fi

    args="$args -v $project_docker_php_dir/conf/php-fpm.conf:/usr/local/etc/php-fpm.conf"

    recursive_mkdir "$project_docker_runtime_dir/app/storage/logs"
    recursive_mkdir "$project_docker_runtime_dir/app/storage/app/public"
    recursive_mkdir "$project_docker_runtime_dir/app/storage/framework/cache"
    recursive_mkdir "$project_docker_runtime_dir/app/storage/framework/sessions"
    recursive_mkdir "$project_docker_runtime_dir/app/storage/framework/testing"
    recursive_mkdir "$project_docker_runtime_dir/app/storage/framework/views"

    args="$args -v $project_docker_runtime_dir/app/storage:$project_path/storage"

    args="$args -v $project_path:$project_path"
    args="$args -w $project_path"

    args="$args --volumes-from $busybox_container"
    args="$args --link $redis_container"

    local cmd='bash docker.sh _run_cmd_php_container'
    run_cmd "docker run -d $args -h $php_container_7 --name $php_container_7 $php_image_7 $cmd"
}

function rm_php() {
    rm_container $php_container_7
}

function to_php() {
    local cmd='bash'
    _send_cmd_to_php_container "cd $project_path; $cmd"
}

function _send_cmd_to_php_container() {
    local cmd=$1
    run_cmd "docker exec -it $php_container_7 bash -c '$cmd'"
}

function _run_cmd_php_container()
{
    run_cmd '/usr/sbin/rsyslogd'
    run_cmd 'bash docker/crontab/start-crontab.sh'
    if [ -f /var/log/php/php-fpm-error.log ]; then
        run_cmd 'touch /var/log/php/php-fpm-error.log'
    fi
    if [ -f /var/log/php/php-fpm-slow ]; then
        run_cmd 'touch /var/log/php/php-fpm-slow.log'
    fi
    run_cmd 'chmod -R a+r /var/log/php/'
    run_cmd '/usr/local/sbin/php-fpm -R'
}