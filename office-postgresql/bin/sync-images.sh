#!/usr/bin/env bash
#
# 从 docker-compose.yml 提取镜像，拉取到本地，打 tag 后推送到阿里云 registry。
#
# 用法:
#   cd office && sh bin/sync-images.sh              # 按 compose 中的镜像地址拉取并推送
#   cd office && sh bin/sync-images.sh --upstream   # 基础镜像从 Docker Hub 拉取，bind-* 从 PULL_REGISTRY 拉取
#   cd office && sh bin/sync-images.sh --pull-only  # 只拉取，不推送
#   cd office && sh bin/sync-images.sh --push-only  # 只推送（假定本地已有正确 tag 的镜像）
#
# 环境变量:
#   TARGET_REGISTRY  目标 registry，默认 registry.cn-shanghai.aliyuncs.com/
#   PULL_REGISTRY    bind-* 自定义镜像的拉取源（--upstream 模式），默认读取 .env 中的 DOCKER_REGISTRY
#   COMPOSE_FILE     compose 文件路径，默认 office/docker-compose.yml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$COMPOSE_DIR/docker-compose.yml}"
TARGET_REGISTRY="${TARGET_REGISTRY:-registry.cn-shanghai.aliyuncs.com/}"

USE_UPSTREAM=false
PULL_ONLY=false
PUSH_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --upstream) USE_UPSTREAM=true ;;
    --pull-only) PULL_ONLY=true ;;
    --push-only) PUSH_ONLY=true ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "未知参数: $arg" >&2
      exit 1
      ;;
  esac
done

if [ "$PULL_ONLY" = true ] && [ "$PUSH_ONLY" = true ]; then
  echo "不能同时指定 --pull-only 和 --push-only" >&2
  exit 1
fi

# 确保 TARGET_REGISTRY 以 / 结尾
[[ "$TARGET_REGISTRY" == */ ]] || TARGET_REGISTRY="${TARGET_REGISTRY}/"

if [ -f "$COMPOSE_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$COMPOSE_DIR/.env"
  set +a
fi

PULL_REGISTRY="${PULL_REGISTRY:-${DOCKER_REGISTRY:-}}"

upstream_for() {
  case "$1" in
    bindoffice/cockroach:v23.2) echo "cockroachdb/cockroach:v23.2" ;;
    postgres:*) echo "$1" ;;
    bindoffice/minio:RELEASE.2021-04-22T15-44-28Z) echo "minio/minio:RELEASE.2021-04-22T15-44-28Z" ;;
    bindoffice/nats:2.9.25) echo "nats:2.9.25" ;;
    bindoffice/redis:6.0) echo "redis:6.0" ;;
    bindoffice/typesense:28.0) echo "typesense/typesense:28.0" ;;
    bindoffice/nginx:1.31.0) echo "nginx:1.31.0" ;;
    bindoffice/rspamd:latest) echo "rspamd/rspamd:latest" ;;
    bindoffice/unbound:latest) echo "mvance/unbound:latest" ;;
    *) return 1 ;;
  esac
}

log() {
  echo "[sync-images] $*"
}

# 从完整镜像名提取 bindoffice/name:tag
extract_bindoffice_ref() {
  local img="$1"
  if [[ "$img" == *bindoffice/* ]]; then
    echo "$img" | sed -E 's|^.*/bindoffice/|bindoffice/|'
  else
    echo "$img"
  fi
}

target_image() {
  local bind_ref
  bind_ref="$(extract_bindoffice_ref "$1")"
  echo "${TARGET_REGISTRY}${bind_ref}"
}

source_image_for_upstream() {
  local bind_ref="$1"
  local upstream
  if upstream="$(upstream_for "$bind_ref")"; then
    echo "$upstream"
    return
  fi
  if [[ "$bind_ref" == bindoffice/bind-* ]]; then
    if [ -z "$PULL_REGISTRY" ]; then
      echo "错误: bind 自定义镜像 ${bind_ref} 需要设置 PULL_REGISTRY 或 .env 中的 DOCKER_REGISTRY" >&2
      exit 1
    fi
    echo "${PULL_REGISTRY}${bind_ref}"
    return
  fi
  echo "错误: 未找到 ${bind_ref} 的上游镜像映射，请补充 UPSTREAM_IMAGES 或使用默认模式" >&2
  exit 1
}

collect_images() {
  local images=""
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    images="$(cd "$COMPOSE_DIR" && docker compose -f "$COMPOSE_FILE" config --images 2>/dev/null || true)"
  fi
  if [ -z "$images" ]; then
    images="$(grep -E '^[[:space:]]+image:' "$COMPOSE_FILE" \
      | sed -E 's/^[[:space:]]+image:[[:space:]]*//' \
      | sed 's/[[:space:]]#.*$//' \
      | sed "s|\${DOCKER_REGISTRY}|${DOCKER_REGISTRY:-}|g")"
  fi
  echo "$images" | sed '/^$/d' | sort -u
}

process_image() {
  local compose_ref="$1"
  local bind_ref target_ref source_ref

  bind_ref="$(extract_bindoffice_ref "$compose_ref")"
  target_ref="$(target_image "$bind_ref")"

  if [ "$USE_UPSTREAM" = true ]; then
    source_ref="$(source_image_for_upstream "$bind_ref")"
  else
    source_ref="$compose_ref"
    # compose 未带 registry 时补上 PULL_REGISTRY
    if [[ "$source_ref" == bindoffice/* ]]; then
      source_ref="${PULL_REGISTRY}${source_ref}"
    fi
  fi

  log "----------------------------------------"
  log "compose: ${compose_ref}"
  log "source:  ${source_ref}"
  log "target:  ${target_ref}"

  if [ "$PUSH_ONLY" != true ]; then
    log "pull ${source_ref}"
    docker pull "$source_ref"
    if [ "$source_ref" != "$target_ref" ]; then
      log "tag ${source_ref} -> ${target_ref}"
      docker tag "$source_ref" "$target_ref"
    fi
  fi

  if [ "$PULL_ONLY" != true ]; then
    if ! docker image inspect "$target_ref" >/dev/null 2>&1; then
      echo "错误: 本地不存在镜像 ${target_ref}，请先拉取或使用 --pull-only 以外的模式" >&2
      exit 1
    fi
    log "push ${target_ref}"
    docker push "$target_ref"
  fi
}

main() {
  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "找不到 compose 文件: $COMPOSE_FILE" >&2
    exit 1
  fi

  log "compose: $COMPOSE_FILE"
  log "target:  ${TARGET_REGISTRY}bindoffice/<image>"
  if [ "$USE_UPSTREAM" = true ]; then
    log "mode:    upstream (基础镜像从 Docker Hub 拉取)"
  else
    log "mode:    compose (按 compose 中的镜像地址拉取)"
  fi

  images="$(collect_images)"
  if [ -z "$images" ]; then
    echo "未从 compose 中解析到任何镜像" >&2
    exit 1
  fi

  count="$(echo "$images" | wc -l | tr -d ' ')"
  log "共 ${count} 个镜像"
  while IFS= read -r img; do
    [ -n "$img" ] || continue
    process_image "$img"
  done <<EOF
$images
EOF

  log "完成"
}

main "$@"
