#!/bin/bash

set -a # 将所有变量自动导出
source ./.env
set +a

docker pull "$DOCKER_REGISTRY"bindoffice/bindinbox:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindmeet:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindoffice:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindsmtp:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindimap:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindtask:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindsearch:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindmqtt:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bindmcp:latest
