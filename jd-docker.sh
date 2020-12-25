#!/bin/bash

JD_PATH=""
SHELL_FOLDER=$(pwd)
log() {
    echo -e "\e[32m$1 \e[0m"
}

cancelrun() {
    if [ $# -gt 0 ]; then
        echo -e "\033[31m $1 \033[0m"
    fi
    exit 1
}

function docker_install() {
    echo "检查Docker......"
    docker -v
    if [ $? -eq 0 ]; then
        echo "检查到Docker已安装!"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ $lsb_dist != "openwrt" ]; then
            echo "openwrt 环境请自行安装docker"
            exit 1
        else
            echo "安装docker环境..."
            curl -sSL https://get.daocloud.io/docker | sh
            echo "安装docker环境...安装完成!"
        fi

    fi
    # 创建公用网络==bridge模式
    #docker network create share_network
}
docker_install

echo -n -e "\e[33m请输入配置文件保存的绝对路径,直接回车为当前目录:\e[0m"
read jd_path
JD_PATH=$jd_path
if [ -z "$jd_path"]; then
    JD_PATH=$SHELL_FOLDER
fi

config_path=$JD_PATH/jd_docker/config
log_path=$JD_PATH/jd_docker/log
log "1.开始创建配置文件目录"
mkdir -p $config_path
mkdir -p $log_path
log "2.开始下载配置文件"
wget -q --no-check-certificate https://gitee.com/evine/jd-base/raw/v3/sample/config.sh.sample -O $config_path/config.sh

if [ $? -ne 0 ]; then
    cancelrun "下载配置文件出错请重试"
fi

wget -q --no-check-certificate https://gitee.com/evine/jd-base/raw/v3/sample/docker.list.sample -O $config_path/crontab.list

if [ $? -ne 0 ]; then
    cancelrun "下载配置文件出错请重试"
fi

echo -n -e "\e[33m配置文件config.sh已经下载到$config_path目录下，\n请使用编辑器大概文件按照说明填写cookie和推送key,\n填写完成后按回车继续:\e[0m"
read confrim
log "3.开始创建容器并执行"
docker run -dit \
    -v $config_path:/jd/config \
    -v $log_path:/jd/log \
    --name jd-script \
    --hostname jd \
    --restart always \
    --network host \
    evinedeng/jd:gitee
if [ $? -ne 0 ]; then
    cancelrun "容器创建出错，请重试"
fi

log "4.docker容器已经运行,下面列出所有在运行的容器"

docker ps