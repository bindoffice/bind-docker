#!/bin/bash

set -a; # 将所有变量自动导出
source ./.env ;
set +a;


List=(bind-inbox bind-task bind-search bind-meetserver bind-filter bind-hub bind-smtp bind-imap bind-office-api bind-mqtt bind-aiserver)

for name in ${List[@]};
do
    echo $name;
    REF="$DOCKER_REGISTRY"hedwi/"$name"
    ID=$(docker images --filter=reference="$REF" --format "{{.ID}}");
    docker image rm -f $ID; 
done
