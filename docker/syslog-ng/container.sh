#!/bin/bash
set -e

function run_syslogng()
{
    local args=''
    local log_path="$project_docker_runtime_dir/syslog-ng"

    recursive_mkdir "$log_path"

    args="$args -v $log_path:/var/log"
    args="$args -p 514:514 -p 601:601/udp"
    args="$args -v $project_docker_syslogng_dir/conf/syslog-ng.conf:/etc/syslog-ng/conf.d/syslog-ng.conf"
    args="$args -v $project_docker_syslogng_dir/conf/sources.list:/etc/apt/sources.list"
    # args="$args --entrypoint bash"
    run_cmd "docker run -d $args --name $syslogng_container $syslogng_image"
}

function rm_syslogng()
{
    rm_container $syslogng_container
}

function restart_syslogng()
{
    rm_syslogng
    run_syslogng
}