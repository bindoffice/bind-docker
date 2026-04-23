#!/bin/bash

set -a; # 将所有变量自动导出
source ./.env ;
set +a;

List=(bind-meetserver bind-static)

for name in ${List[@]};
do
    echo $name;
    REF="$DOCKER_REGISTRY"bindoffice/"$name"
    ID=$(docker images --filter=reference="$REF" --format "{{.ID}}");
    docker image rm -f $ID;
done
