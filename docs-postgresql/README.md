# docs-postgresql

`docs/` 的 PostgreSQL 版本：数据库由 PostgreSQL 替代 bindsql（CockroachDB），使用 `postgres` + `postgres-init` 服务、连接串使用 `POSTGRES_*` 变量，其余服务与 `docs/` 完全一致。

This is the PostgreSQL variant of `docs/`: PostgreSQL replaces bindsql (CockroachDB) via the `postgres` + `postgres-init` services and the `POSTGRES_*` variables; every other service is the same as `docs/`.

## 使用 Usage

```
  cp env.example .env

  # change variables in .env

  make openssl

  make
```

打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

## 共享配置需两处同步 Shared config must be kept in sync

本目录由 `docs/` 复制而来。除数据库相关部分外，两者**共享同一套配置**，在仓库中保存为两份副本：

- `bin/`（证书、更新、镜像同步等脚本）
- `nginx/conf/`、`nginx/conf.d/`
- `redis/redis.conf`、`nats/nats.conf`
- `bindmeet/config.yaml`
- `1`、`2`（CA 证书包）

修改以上任一文件时，请**同时更新 `docs/` 和 `docs-postgresql/`**，否则会造成配置漂移。详见仓库根目录 [../README.md](../README.md)。
