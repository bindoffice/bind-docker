# office

自建办公套件的完整部署（邮箱、通讯录、日历、AI、会议、聊天、看板、云盘、文档、表格、演示、笔记），数据库使用 PostgreSQL。

The full self-hosted office suite (mail, contacts, calendar, AI, meet, chat, kanban, drive, docs, sheets, slides, note), backed by PostgreSQL.

## 使用 Usage

```
  cp env.example .env

  # change variables in .env

  make openssl

  make
```

打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

## 数据库 / 缓存端口暴露 Exposing the database and cache ports

`postgres` 和 `redis` 不使用 host 网络（host 模式下 `ports` 会被忽略，端口无法暴露给宿主机），两者都把对应的 `*_ADDR` 变量直接当作发布地址：

`postgres` and `redis` do not use host networking (`ports` is ignored in host mode, so nothing can reach the host); both use their `*_ADDR` variable as the published address:

| 变量 Variable | 默认 Default | 对局域网开放 On the LAN |
| --- | --- | --- |
| `POSTGRES_ADDR` | `127.0.0.1:5432` | `0.0.0.0:5432` |
| `REDIS_ADDR` | `127.0.0.1:6379` | `0.0.0.0:6379` |

默认只发布到宿主机回环，供本地客户端连接 / by default they are published on the host loopback only, for local clients:

```
psql "postgresql://postgres:<POSTGRES_PASSWORD>@127.0.0.1:5432/<DB_NAME>?sslmode=disable"
redis-cli -h 127.0.0.1 -p 6379
```

⚠️ redis 没有密码（`redis.conf` 未设 `requirepass`，`REDIS_PASSWORD` 为空），`REDIS_ADDR="0.0.0.0:6379"` 等于把 session/cache 库对整个局域网敞开，请保持默认的 `127.0.0.1`。

⚠️ redis has no password (`requirepass` is not set in `redis.conf` and `REDIS_PASSWORD` is empty), so `REDIS_ADDR="0.0.0.0:6379"` leaves the session/cache store wide open on the LAN — keep the `127.0.0.1` default.

`redis.conf` 里是 `bind 127.0.0.1`，容器只监听 loopback 时发布端口会 `Connection refused`，所以 compose 用命令行参数覆盖为 `--bind 0.0.0.0`，这样不必改动 `office/`、`docs/`、`meet/` 共用的 `redis/redis.conf`。

`redis.conf` binds `127.0.0.1`; a container listening on loopback alone makes the published port fail with `Connection refused`, so the compose overrides it on the command line with `--bind 0.0.0.0`, which keeps the `redis/redis.conf` shared by `office/`, `docs/` and `meet/` untouched.

其余服务仍以 host 网络运行，通过 `127.0.0.1:<端口>` 访问这两个已发布端口，`BIND_SQLDB`、`BIND_SESSION_HEDIS_HOST` 等无需改动。注意经发布端口进来的连接源地址不是 `127.0.0.1`，postgres 因此会走 `pg_hba.conf` 的 `host all all all scram-sha-256`，必须带 `POSTGRES_PASSWORD`。

Every other service still runs with host networking and reaches these two published ports over `127.0.0.1:<port>`, so `BIND_SQLDB`, `BIND_SESSION_HEDIS_HOST` etc. need no change. Note that connections arriving through the published port do not come from `127.0.0.1`; postgres therefore matches `host all all all scram-sha-256` in `pg_hba.conf` and must supply `POSTGRES_PASSWORD`.

## 证书自动续期 Certificate auto-renewal

`make cron` 安装 crontab（默认每天执行一次 `make renew`），`make uncron` 卸载，`sh bin/cert-cron.sh show` 查看。`make renew` 是幂等的，仅在证书剩余时间少于 `CERT_RENEW_DAYS`（默认 30 天）时才真正续期并 reload nginx。详见仓库根目录 [../README.md](../README.md)。

## 共享配置需多处同步 Shared config must be kept in sync

本目录与 `docs/`、`meet/` 共用证书脚本、`redis/redis.conf` 等文件，在仓库中保存为多份副本，修改时请同步更新，否则会造成配置漂移。清单详见仓库根目录 [../README.md](../README.md)。
