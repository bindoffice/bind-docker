# bind-docker

# About

  Self-hosted office suite, google workspace alternative.

# 文档 Documentation

zh-hans: [办公套件文档 中文版](https://bindoffice.github.io/documentation/office/zh-hans/) en-us: [Work suite documentation](https://bindoffice.github.io/documentation/office/en-us/)


zh-hans: [视频会议文档中文版](https://bindoffice.github.io/documentation/meet/zh-hans/)   en-us: [Meet documentation](https://bindoffice.github.io/documentation/meet/zh-hans/)


- [Discord](https://discord.gg/rS6FUqNvG5)
- [QQ群](https://qm.qq.com/cgi-bin/qm/qr?k=JbieSiHKJBBSrI45cOSP4BG6ll5W9Ct3&jump_from=webapi&authKey=QrQoCwTf3BCPXHbxsYD/nHEcp284BPQQdnrFScq1564ifzNRSfwAKJAOF8Sz5BqX)

# 使用 Usage


```
  #  国外用户
  git clone https://github.com/bindoffice/bind-docker.git


  cd bind-docker/office 

  cp env.example .env

  #change variables in .env

  # generate self signed ssl certs for nginx, will be replaced by `make cert`
  make openssl

  # docker-compose up -d 
  make
  
```
打开首页 [http://127.0.0.1:40008](http://127.0.0.1:40008)

