#!/bin/bash
set -e

function run_nginx_fpm()
{
    local nginx_log_path="$project_docker_runtime_dir/nginx-fpm"
    recursive_mkdir "$nginx_log_path"
    local nginx_docker_sites_fpm_conf_dir="$project_docker_persistent_dir/nginx-fpm-config"

    args="--restart=always"

    args="$args -p $nginx_port:80"

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


function rm_nginx_fpm()
{
    rm_container $nginx_container_fpm
}

function restart_nginx()
{
    rm_nginx_fpm
    run_nginx_fpm
}

