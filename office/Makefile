DEPS_SERVICES = bindsql bindstore nats redis typesense bindmqtt rspamd unbound
APP_SERVICES = bindoffice bindsearch bindmeet bindinbox bindtask bindsmtp bindimap bindmcp nginx
WEB_SERVICES = bindinbox

all: compose-up

compose-up: deps-up apps-up

deps-up:
	docker compose up -d $(DEPS_SERVICES)
	docker compose up --wait bindsql-init

deps-down:
	docker compose stop $(DEPS_SERVICES)

deps-restart:
	docker compose restart $(DEPS_SERVICES)

apps-up:
	docker compose up -d $(APP_SERVICES)

apps-down:
	docker compose stop $(APP_SERVICES)

apps-restart:
	docker compose restart $(APP_SERVICES)

web-restart:
	docker compose restart $(WEB_SERVICES)

orb:
	docker compose up -d

cert:generate copy


renew:
	sh bin/cert-renew.sh && \cp -f inbox/certs/cert.key nginx/certs/cert.key && \cp -f inbox/certs/cert.crt nginx/certs/cert.crt && \cp -f inbox/certs/cert.key smtp/certs/cert.key && \cp -f inbox/certs/cert.crt smtp/certs/cert.crt


openssl:
	sh bin/openssl.sh

generate:
	sh bin/cert.sh

copy:
	 \cp -f inbox/certs/cert.key nginx/certs/cert.key && \cp -f inbox/certs/cert.crt nginx/certs/cert.crt
	 \cp -f inbox/certs/cert.key smtp/certs/cert.key && \cp -f inbox/certs/cert.crt smtp/certs/cert.crt

stop: #docker stop `docker ps -aq`
	docker compose down

down:
	docker compose down

remove-image:
	sh bin/remove.sh

remove: down remove-image

upgrade: remove compose-up

update:
	sh bin/update.sh
