#!/bin/bash
set -e

nginx_image=nginx:1.11
nginx_container_fpm=$app-nginx-fpm

project_docker_nginx_dir="$project_docker_path/nginx"
project_docker_runtime_dir="$project_docker_path/runtime"

function run_nginx_fpm()
{

    local nginx_log_path="$project_docker_runtime_dir/nginx-fpm"
    recursive_mkdir "$nginx_log_path"
    local nginx_docker_sites_fpm_conf_dir="$project_docker_nginx_dir/nginx-fpm-config"

    args="--restart=always"

    args="$args -p 8081:80"

    # nginx config
    args="$args -v $project_docker_nginx_dir/conf/nginx.conf:/etc/nginx/nginx.conf"

    # for the other sites
    args="$args -v $project_docker_nginx_dir/conf/extra/:/etc/nginx/extra"

    # logs
    args="$args -v $nginx_log_path:/var/log/nginx"

    # generated nginx docker sites config
    args="$args -v $nginx_docker_sites_fpm_conf_dir:/etc/nginx/docker-sites"

    args="$args --link $php_container"

    args="$args --volumes-from $busybox_container"

    run_cmd "docker run -d $args --name $nginx_container_fpm $nginx_image"
}


function rm_nginx()
{
    rm_container $nginx_container_fpm
}

function restart_nginx()
{
    rm_nginx
    run_nginx_fpm
}