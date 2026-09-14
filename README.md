# bind-docker

# About 关于

  Self-hosted office suite. Website: https://bindoffice.com

- Mail           邮箱
- Contacts       通讯录
- Calendar       日历
- AI             AI
- Meet           会议
- Chat           聊天
- Kanban         看板
- Drive          云盘
- Docs           文档
- Sheets         表格
- Slides         演示
- Note           笔记

# 文档 Documentation

zh-hans: [办公套件文档 中文版](https://bindoffice.github.io/documentation/office/zh-hans/) en-us: [Work suite documentation](https://bindoffice.github.io/documentation/office/en-us/)

zh-hans: [视频会议文档中文版](https://bindoffice.github.io/documentation/meet/zh-hans/)   en-us: [Meet documentation](https://bindoffice.github.io/documentation/meet/en-us/)

- [QQ群](https://qm.qq.com/cgi-bin/qm/qr?k=JbieSiHKJBBSrI45cOSP4BG6ll5W9Ct3&jump_from=webapi&authKey=QrQoCwTf3BCPXHbxsYD/nHEcp284BPQQdnrFScq1564ifzNRSfwAKJAOF8Sz5BqX)

# 使用 Usage

## Office 办公套件

```
  git clone https://github.com/bindoffice/bind-docker.git

  cd bind-docker/office

  cp env.example .env

  # change variables in .env

  # generate self signed ssl certs for nginx, will be replaced by `make cert`
  make openssl

  # docker-compose up -d
  make
```


打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

### Office（PostgreSQL 版）

数据库用 PostgreSQL 替代 bindsql（CockroachDB），配置在 `office-postgresql/`，用法相同：

```
  cd bind-docker/office-postgresql

  cp env.example .env

  # change variables in .env

  make openssl

  make
```

打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

## Meet 视频会议（独立部署）

详见 [meet/README.md](meet/README.md)。

```
  cd bind-docker/meet

  cp env.example .env

  # change variables in .env

  make openssl

  make
```

打开首页 [http://127.0.0.1:8888](http://127.0.0.1:8888)

# 目录结构 Layout

每套服务放在独立目录，互不影响：

| 目录 | 数据库 | 说明 |
| --- | --- | --- |
| `office/` | bindsql（CockroachDB） | 办公套件 |
| `office-postgresql/` | PostgreSQL | 办公套件，数据库换成 PostgreSQL |
| `docs/` | bindsql（CockroachDB） | 文档（精简部署） |
| `docs-postgresql/` | PostgreSQL | 文档，数据库换成 PostgreSQL |
| `meet/` | — | 视频会议（独立部署） |

PostgreSQL 版本使用 `postgres` + `postgres-init` 服务（`POSTGRES_*` 变量），bindsql 版本使用 `bindsql` + `bindsql-init`（`BINDSQL_ADDR`）。四个目录的 compose 不再共享 `container_name`，容器名按目录名自动生成，因此可以在目录之间安全切换部署。

# 共享配置需两处同步 Shared config must be kept in sync

`office-postgresql/` 由 `office/` 复制而来，`docs-postgresql/` 由 `docs/` 复制而来。除数据库相关部分外，两者**共享同一套配置**，在仓库中保存为两份副本：

- `bin/`（证书、更新、镜像同步等脚本）
- `nginx/conf/`、`nginx/conf.d/`
- `redis/redis.conf`、`nats/nats.conf`
- `bindmeet/config.yaml`
- `1`、`2`（CA 证书包）

修改以上任一文件时，请**同时更新对应的两个目录**（`office/` ⇄ `office-postgresql/`，`docs/` ⇄ `docs-postgresql/`），否则会造成配置漂移。
