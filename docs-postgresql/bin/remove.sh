#!/bin/bash

set -a; # 将所有变量自动导出
source ./.env ;
set +a;


List=(bindinbox bindsearch bindmeet bindoffice bindmqtt bindmcp bindstore)

for name in ${List[@]};
do
    echo $name;
    REF="$DOCKER_REGISTRY"bindoffice/"$name"
    ID=$(docker images --filter=reference="$REF" --format "{{.ID}}");
    [ -n "$ID" ] || continue
    docker image rm -f $ID; 
done
