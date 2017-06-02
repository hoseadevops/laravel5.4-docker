#!/bin/bash
set -e

php_image=hosea-php5.6
php_container=$app-php5.6

project_docker_php_dir="$project_docker_path/php"
project_docker_runtime_dir="$project_docker_path/runtime"
project_docker_php_image_dir="$project_docker_path/php/image"


function build_php()
{
    docker build -t $php_image $project_docker_php_image_dir
}

function run_php()
{
    local args='--restart=always'

    args="$args --cap-add SYS_PTRACE"

    args="$args -v $project_docker_runtime_dir/php:/var/log/php"

    args="$args -v $project_docker_runtime_dir/crontab:/var/log/crontab"

    if [ "$env" = 'dev' ]; then
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

    local cmd='bash manager.sh _container_run_cmd'
    run_cmd "docker run -d $args -h $php_container --name $php_container $php_image $cmd"
}


function _container_run_cmd()
{
    run_cmd '/usr/sbin/rsyslogd'
    run_cmd 'bash crontab/start-crontab.sh'
    if [ -f /var/log/php/php-fpm-error.log ]; then
        run_cmd 'touch /var/log/php/php-fpm-error.log'
    fi
    if [ -f /var/log/php/php-fpm-slow ]; then
        run_cmd 'touch /var/log/php/php-fpm-slow.log'
    fi
    run_cmd 'chmod -R a+r /var/log/php/'
    run_cmd '/usr/local/sbin/php-fpm -R'
}