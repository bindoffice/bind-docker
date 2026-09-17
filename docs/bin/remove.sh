#!/bin/sh

set -a; # 将所有变量自动导出
. ./.env ;
set +a;


# 与 bin/update.sh 拉取的镜像保持一致 / keep in sync with the images pulled by bin/update.sh
List="bindinbox bindsearch bindmeet bindoffice bindmqtt bindmcp bindstore"

for name in $List;
do
    echo $name;
    # 同时匹配 <DOCKER_REGISTRY>bindoffice/x 与 bindoffice/x 两种本地名字（多个 reference
    # filter 之间是「或」；`*` 不跨 `/`，所以要写成 */bindoffice/x 而不是 *bindoffice/x）
    # Match both <DOCKER_REGISTRY>bindoffice/x and plain bindoffice/x (filters are OR-ed;
    # `*` never spans `/`, hence the leading `*/`).
    ID=$(docker images \
        --filter=reference="bindoffice/$name" \
        --filter=reference="*/bindoffice/$name" \
        --format "{{.ID}}" | sort -u);
    # 镜像不在本地时 ID 为空，跳过，避免 `docker image rm` 报错中断 make
    # Skip when the image is absent locally, so `docker image rm` does not abort make
    if [ -n "$ID" ]; then
        docker image rm -f $ID;
    fi
done
