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

数据库统一使用 PostgreSQL：`postgres` + `postgres-init` 服务，连接串由 `POSTGRES_*` 变量拼装。

PostgreSQL is the only supported database: the `postgres` + `postgres-init` services, with the connection string built from the `POSTGRES_*` variables.

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

详见 [office/README.md](office/README.md) / See [office/README.md](office/README.md).

## Docs 文档（精简部署）

```
  cd bind-docker/docs

  cp env.example .env

  # change variables in .env

  make openssl

  make
```

打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

详见 [docs/README.md](docs/README.md) / See [docs/README.md](docs/README.md).

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
| `office/` | PostgreSQL | 办公套件 |
| `docs/` | PostgreSQL | 文档（精简部署） |
| `meet/` | — | 视频会议（独立部署） |

容器名按目录名自动生成（compose 不再共享 `container_name`），因此 `office/`、`docs/`、`meet/` 可以在同一台机器上并存。

`postgres` 和 `redis` **不用 host 网络**：host 模式下 `ports` 会被忽略、端口无法暴露给宿主机，因此它们把 `POSTGRES_ADDR` / `REDIS_ADDR` 同时当作发布地址，默认分别是 `127.0.0.1:5432`、`127.0.0.1:6379`（仅宿主机本机可访问），设成 `0.0.0.0:...` 可对局域网开放（redis 无密码，不建议）。

`postgres` and `redis` are **not** on host networking: `ports` is ignored in host mode, so those ports would never reach the host. They therefore use `POSTGRES_ADDR` / `REDIS_ADDR` as the published address too — `127.0.0.1:5432` and `127.0.0.1:6379` (host loopback only) by default, or `0.0.0.0:...` to expose them on the LAN (not recommended for the passwordless redis).

# 共享配置需多处同步 Shared config must be kept in sync

`office/`、`docs/`、`meet/` 是三个独立部署，但以下文件在仓库中保存为多份副本，内容应当保持一致：

- 证书脚本 `bin/cert-cron.sh`、`bin/cert-distribute.sh`、`bin/cert-renew.sh`、`bin/cert.sh`、`bin/openssl.sh`（`office/`、`docs/`、`meet/` 三处）
- `redis/redis.conf`（`office/`、`docs/`、`meet/` 三处）
- `nats/nats.conf`（`office/`、`docs/`）
- `bindmeet/config.yaml`（`office/`、`docs/`）
- `1`、`2`（CA 证书包，`office/`、`docs/`、`meet/` 三处）

`nginx/` 配置以及 `bin/remove.sh`、`bin/update.sh` 依赖各部署实际运行的服务，`docs/` 作为精简部署与 `office/` 不同，属正常差异。

修改以上任一文件时，请**同时更新对应的多个目录**，否则会造成配置漂移。
