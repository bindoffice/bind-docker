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

# 证书自动续期 Certificate auto-renewal

`make cert` 通过 ACME（Let's Encrypt 等）申请正式证书，有效期只有 3 个月，手动 `make renew` 很容易忘记。装一条 crontab 即可自动续期：

```
  make cron      # 安装定时续期任务（可重复执行，会替换旧任务）
  make uncron    # 卸载
  sh bin/cert-cron.sh show   # 查看已安装的任务
```

定时任务实际执行的是 `make renew`，它是**幂等**的：脚本先用 `openssl x509 -checkend` 检查 nginx 正在使用的证书，剩余有效期大于 `CERT_RENEW_DAYS`（默认 30 天）时直接跳过，所以每天跑也不会触发 Let's Encrypt 的重复证书频率限制（同一组域名每周 5 张）。

只有临近过期时才会：调用 ACME 续期接口 → 把新证书分发到 `nginx/certs`、`smtp/certs`、`imap/certs` → reload nginx、重启 `bindsmtp`/`bindimap`（需要立即生效的邮件服务）。日志追加写入 `<部署目录>/logs/cert-renew.log`。

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `CERT_RENEW_DAYS` | `30` | 剩余天数少于该值时续期 |
| `CERT_CRON_SCHEDULE` | `0 3 * * *` | `make cron` 写入 crontab 的计划 |

两个变量写在 `.env` 里（见 `env.example`）。crontab 归属执行 `make cron` 的用户，该用户必须能免 sudo 使用 Docker（在 `docker` 组内，或直接用 root 执行 `make cron`）。

不想用 crontab 的话，也可以用 systemd timer 或其他调度器定时执行 `cd <部署目录> && make renew`。需要强制续期（忽略剩余天数）时：`CERT_FORCE_RENEW=1 sh bin/cert-renew.sh`。

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
