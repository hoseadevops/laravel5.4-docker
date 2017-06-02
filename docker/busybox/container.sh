#!/bin/bash
set -e

busybox_image=busybox
busybox_container=$app-busybox

project_docker_busybox_path="$project_docker_path/busybox"

function run_busybox()
{
    local args=''
    args="$args -v $project_path:$project_path"
    run_cmd "docker run $args --name $busybox_container $busybox_image /bin/true"
}

function rm_busybox()
{
    rm_container $busybox_container
}