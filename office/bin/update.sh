#!/bin/bash

set -a # 将所有变量自动导出
source ./.env
set +a

docker pull "$DOCKER_REGISTRY"bindoffice/bind-inbox:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-meetserver:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-office-api:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-smtp:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-imap:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-task:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-search:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-mqtt:latest
docker pull "$DOCKER_REGISTRY"bindoffice/bind-mcp:latest
