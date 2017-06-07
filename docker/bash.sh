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
# demo： recursive_mkdir "/opt/data/hosea"
#--------------------------------------------
function recursive_mkdir()
{
    if [ ! -d $1 ]; then
        run_cmd "mkdir -p $1"
    fi
}

#--------------------------------------------
# 递归创建目录 通过传入的文件地址
#
# demo： recursive_mkdir_with_file "/opt/data/hosea/a.txt"
#--------------------------------------------

function recursive_mkdir_with_file()
{
    recursive_mkdir $(dirname $1)
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
# 容器是否在运行
#
# demo: container_is_running "container_name"
#--------------------------------------------
function container_is_running()
{
    local container_name=$1
    local num=$(docker ps -a -f name="^/$container_name$" -q | wc -l)
    if [ "$num" == "1" ]; then
        local ret=$(docker inspect -f {{.State.Running}} $1)
        echo $ret
    else
        echo 'false'
    fi
}


function docker0_ip()
{
    local host_ip=$(ip addr show docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | awk '{print $1}' | head  -1)
    echo $host_ip
}

#--------------------------------------------
# 列出包含的命令
#
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
# 修改host
# sh docker.sh updateHost www.baidu.com 127.0.0.1
#--------------------------------------------
function updateHost()
{
    local in_url="$2"
    local in_ip="$3"

    # 域名下的IP
    inner_host=`cat /etc/hosts | grep ${in_url} | awk '{print $1}'`
    if [[ ${inner_host} = ${in_ip} ]];
    then
        echo "${inner_host}  ${in_url} ok, do nothing."
    else
        # 替换 http://man.linuxde.net/sed
        # sudo sed -i "" "s/${inner_host:='updateHost'}/${in_ip}/g" /etc/hosts

        inner_ip_map="${in_ip} ${in_url}"
        # sudo 只能作用于echo 操作符仍然 >> 需要权限 sh -c 可以让sudu 命令作用于整个语句
        sudo sh -c "echo ${inner_ip_map} >> /etc/hosts"
        # tee -a 追加 等同于 >>
        # echo ${inner_ip_map}|sudo tee -a /etc/hosts

        if [ $? = 0 ]; then
           echo "${inner_ip_map} to hosts success host is `cat /etc/hosts`"
        fi
    fi
}

function read_kv_config()
{
    local file=$1
    local key=$2
    cat $file | grep "$key=" | awk -F '=' '{print $2}'
}
#--------------------------------------------
# 模板变量替换 生成新文件
#
#--------------------------------------------
function render_local_config()
{
    local config_key=$1
    local template_file=$2
    local config_file=$3
    local out=$4

    shift
    shift
    shift
    shift

    local config_type=yaml
    cmd="curl -s -F 'template_file=@$template_file' -F 'config_file=@$config_file' -F 'config_key=$config_key' -F 'config_type=$config_type'"
    for kv in $*
    do
        cmd="$cmd -F 'kv_list[]=$kv'"
    done
    cmd="$cmd $CONFIG_SERVER/render-config > $out"
    run_cmd "$cmd"
    head $out && echo
}

#--------------------------------------------
# 变量扩展 默认值类用法
#
# ${parameter-word} 若parameter变量未定义，则扩展为word。
# ${parameter:-word} 若parameter变量未定义或为空，则扩展为word。
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