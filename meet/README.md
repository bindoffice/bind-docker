# bind-meet 视频会议

# 使用

```
  git clone https://github.com/bindoffice/bind-docker.git
  cd bind-docker/meet
  cp env.example .env

  # change variables in .env

  # generate self signed ssl certs for nginx, will be replaced by `make cert`
  make openssl

  make
```

打开首页 [http://127.0.0.1:8888](http://127.0.0.1:8888)

# 证书

- 本地开发：运行 `make openssl` 生成自签名证书到 `nginx/certs/`
- 生产环境：配置好域名解析后运行 `make cert`，通过 ACME 申请正式证书

# LDAP 认证

在 `.env` 中配置以下变量（对应 `meetserver/config.yaml`）：

- `MEET_AUTH_TYPE` — 认证类型，如 `ldap`
- `MEET_LDAP_ENABLED` — 是否启用 LDAP
- `MEET_LDAP_ADDR` — LDAP 地址，如 `ldap://127.0.0.1:389`
- `MEET_LDAP_BASE_DN` — Base DN，如 `dc=example,dc=com`
