#!/bin/bash
set -e

php_image=hosea-php5.6
project_docker_php_path="$project_docker_path/php"

project_docker_php_image_dir="$project_docker_path/php/image"


function build_php() {
    docker build -t $php_image $project_docker_php_image_dir
}

