#!/bin/bash

NC='\033[0m'      # Normal Color
RED='\033[0;31m'  # Error Color
CYAN='\033[0;36m' # Info Color

#--------------------------------------------
# 执行命令
#
# demo： run_cmd "mkdir -p $1"
#--------------------------------------------
function run_cmd()
{
    local t=`date`
    echo "$t: $1"
    eval $1
}

#--------------------------------------------
# 递归创建目录
#
# demo： recursive_mkdir "/opt/data/hexing"
#--------------------------------------------
function recursive_mkdir()
{
    if [ ! -d $1 ]; then
        run_cmd "mkdir -p $1"
    fi
}


#--------------------------------------------
# 删除容器
#
# demo: rm_container "container_name"
#--------------------------------------------
function rm_container()
{
    local container_name=$1
    local cmd="docker ps -a -f name='^/$container_name$' | grep '$container_name' | awk '{print \$1}' | xargs -I {} docker rm -f --volumes {}"
    run_cmd "$cmd"
}

#--------------------------------------------
# 列出包含的命令
#
# demo: rm_container "container_name"
#--------------------------------------------
function list_contains()
{
    local var="$1"
    local str="$2"
    local val

    eval "val=\" \${$var} \""
    [ "${val%% $str *}" != "$val" ]
}

#--------------------------------------------
#变量扩展 默认值类用法
#   ${parameter-word} 若parameter变量未定义，则扩展为word。
#   ${parameter:-word} 若parameter变量未定义或为空，则扩展为word。
#--------------------------------------------

action=${1:-help}
if [ "$action" = 'init' ]; then
    if [ $# -lt 1 ]; then
        echo "Usage sh $0 init";
        exit 1
    fi
    init
    exit 0
fi