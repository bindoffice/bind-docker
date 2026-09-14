#!/bin/sh

set -a # 将所有变量自动导出
. ./.env
set +a

docker pull "$DOCKER_REGISTRY"bindoffice/bind-meetserver:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-static:latest
