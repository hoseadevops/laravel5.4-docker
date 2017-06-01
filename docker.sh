#!/bin/bash

set -e

project_path=$(cd $(dirname $0); pwd -P)
project_docker_path="$project_path/docker"

developer_name=$('whoami')
app_basic_name="laravel"
app="$developer_name-$app_basic_name"

source $project_docker_path/bash.sh

source $project_path/mysql/container.sh


