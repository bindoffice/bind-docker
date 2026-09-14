DEPS_SERVICES = bindsql bindstore nats redis typesense bindmqtt
APP_SERVICES = bindoffice bindsearch bindmeet bindinbox bindmcp nginx
WEB_SERVICES = bindinbox
POSTGRES_COMPOSE = docker-compose.postgres.yml
POSTGRES_DEPS_SERVICES = postgres bindstore nats redis typesense bindmqtt

all: compose-up

compose-up: deps-up apps-up

compose-up-postgres: deps-up-postgres apps-up-postgres

deps-up-postgres:
	docker compose -f $(POSTGRES_COMPOSE) up -d $(POSTGRES_DEPS_SERVICES)
	docker compose -f $(POSTGRES_COMPOSE) up --wait postgres-init

apps-up-postgres:
	docker compose -f $(POSTGRES_COMPOSE) up -d $(APP_SERVICES)

down-postgres:
	docker compose -f $(POSTGRES_COMPOSE) down

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
	sh bin/cert-renew.sh && \cp -f bindinbox/certs/cert.key nginx/certs/cert.key && \cp -f bindinbox/certs/cert.crt nginx/certs/cert.crt


openssl:
	sh bin/openssl.sh

generate:
	sh bin/cert.sh

copy:
	 \cp -f bindinbox/certs/cert.key nginx/certs/cert.key && \cp -f bindinbox/certs/cert.crt nginx/certs/cert.crt

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
