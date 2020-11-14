include .env
export

.SILENT:

.PHONY: help restart create_user create_db

define HELPTEXT

	Usage make database_<command>

	commands:
	    restart             restart the service
	    create_user         create database user
	    create_db           create the database

endef

UID ?= 210
GID ?= 210

help:
	$(info $(HELPTEXT))

restart:
	docker service update $(SERVICE)

create_user:
	./service_exec $(SERVICE) psql -d postgres -U $(DBA_USER) -c 'CREATE ROLE $(DB_USER) WITH LOGIN CREATEDB PASSWORD '\''$(DB_PASS)'\'';'

create_db:
	./service_exec $(SERVICE) psql -d postgres -U $(DBA_USER) -c 'CREATE DATABASE $(DB_NAME) WITH OWNER $(DB_USER);'
