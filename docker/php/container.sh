#!/bin/bash
set -e

php_image=hosea-php5.6
project_docker_php_path="$project_docker_path/php"

project_docker_php_image_dir="$project_docker_path/php/image"


function build_php()
{
    docker build -t $php_image $project_docker_php_image_dir
}

function run_php()
{
    local args='--restart=always'
    args="$args -v $app_log_dir/php:/var/log/php"
    args="$args -v $app_log_dir/crontab:/var/log/crontab"

    args="$args -v $prj_path/docker/php/conf/php-dev.ini:/usr/local/etc/php/php.ini"
    args="$args -v $prj_path/docker/php/conf/php-fpm.conf:/usr/local/etc/php-fpm.conf"

    ensure_dir "$app_php_storage_dir/core/logs"
    ensure_dir "$app_php_storage_dir/module/logs"
    ensure_dir "$app_php_storage_dir/module/framework/sessions"
    ensure_dir "$app_php_storage_dir/module/framework/cache"
    ensure_dir "$app_php_storage_dir/service/logs"

    args="$args -v $app_php_storage_dir/core:$docker_code_root_dir/9douyu-core/storage"
    args="$args -v $app_php_storage_dir/module:$docker_code_root_dir/9douyu-module/storage"
    args="$args -v $app_php_storage_dir/service:$docker_code_root_dir/9douyu-service/storage"

    args="$args -v $prj_path:$prj_path"
    args="$args -w $prj_path"

    args="$args --volumes-from $data_container"
    args="$args --link $redis_container"

    local cmd=$1
    run_cmd "docker run -d $args -h $php_container --name $php_container $php_image $cmd"

}