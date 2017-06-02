#!/bin/bash
set -e

redis_image=redis:3.0.1
redis_container=$app-redis3.0.1
project_docker_redis_dir="$project_docker_path/redis"


function run_redis()
{
    local args="--restart always"
    # config
    args="$args -v $project_docker_redis_dir/conf/redis.conf:/usr/local/etc/redis/redis.conf"
    run_cmd "docker run -d $args --name $redis_container $redis_image"
}

function rm_redis()
{
    rm_container $redis_container
}

function to_redis()
{
    local cmd='redis-cli'
    run_cmd "docker exec -it $redis_container bash -c '$cmd'"
}

function restart_redis()
{
    rm_redis
    run_redis
}
