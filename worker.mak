include .env
export

.SILENT:

.PHONY: help build publish shell gems_install gems_update db_migrate db_seed list ps start-% halt-% stop-% restart-% logs-% shell-%

define HELPTEXT

	Usage make worker_<command>

	commands:

	    build               build the docker image
	    publish             publish the image to the registry

	    shell               interactive bash shell
	    gems_install        install gems
	    gems_update         update gems
	    db_migrate          migrate database
	    db_seed             seed database

	    list                print list of available worker configurations
	    ps                  show running workers

	    start-%             start worker for configuration %
	    halt-%              prevent worker % from taking up new jobs
	    stop-%              stop all workers for %
	    restart-%           restart all workers for %
	    logs-%              print the log for worker %
	    shell-%             start interactive shell on worker %
endef

WORKER_IMAGE ?= registry.docker.libis.be/teneo/ingest_worker
UID ?= $(shell id -u)
GID ?= $(shell id -g)

help:
	$(info $(HELPTEXT))

## Docker image tasks ##

collect:
	tar -cf worker.tar --owner=$(UID) --group=$(GID) Gemfile Rakefile worker.rb bin config db lib

build: collect
	docker build --tag $(WORKER_IMAGE) --build-arg UID=$(UID) --build-arg GID=$(GID) -f Dockerfile.worker .

publish:
	docker push $(WORKER_IMAGE)

## Settings ##

ENV_VARS := -e APP_ENV=$(APP_ENV) -e DB_HOST=$(DB_HOST) -e DB_PORT=$(DB_PORT) -e REDIS_URL=redis://queue:6379/0
MOUNTS := --mount type=bind,source=${PWD}/bundle,destination=/bundle-gems \
	--mount type=bind,source=${ORACLE_CLIENT},destination=/oracle-client \
	--mount type=bind,source=${PWD}/.env,destination=/ingest/.env \
	--mount type=bind,source=${PWD}/Gemfile,destination=/ingest/Gemfile \
	--mount type=bind,source=${PWD}/Rakefile,destination=/ingest/Rakefile \
	--mount type=bind,source=${PWD}/worker.rb,destination=/ingest/worker.rb \
	--mount type=bind,source=${PWD}/bin,destination=/ingest/bin \
	--mount type=bind,source=${PWD}/config,destination=/ingest/config \
	--mount type=bind,source=${PWD}/db,destination=/ingest/db \
	--mount type=bind,source=${PWD}/lib,destination=/ingest/lib \
	--mount type=bind,source=${PWD}/testrun.rb,destination=/ingest/testrun.rb \
	--mount type=bind,source=/nas,destination=/nas

NAME_PREFIX := $(SERVICE)
PROC_LABEL := teneo.ingester=proc
SHELL_LABEL := teneo.ingester=shell

mkfile_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CFG_DIR := $(mkfile_dir)/config
CONFIGS = $(shell ls -1 $(CFG_DIR)/sidekiq-*.yml 2>/dev/null | awk -F '-' '{print $$2}' | awk -F '.' '{print $$1}')
SERVICES = $(shell docker service ls --quiet --filter label=$(PROC_LABEL))

## General mainternance tasks ##

DOCKER_RUN_CMD := docker run --rm -it --network $(NET) --label $(SHELL_LABEL) $(ENV_VARS) $(MOUNTS) $(WORKER_IMAGE)
shell:
	$(DOCKER_RUN_CMD) bash

gems_install:
	$(DOCKER_RUN_CMD) bundle install

gems_update:
	$(DOCKER_RUN_CMD) bundle update

db_migrate:
	$(DOCKER_RUN_CMD) bundle exec rake db:migrate

db_seed:
	$(DOCKER_RUN_CMD) bundle exec rake db:seed

## WORKERS tasks ###

list:
	echo Available ingester configurations:
	printf " - %s\n" $(CONFIGS) || true

ps:
	[ -z "$(SERVICES)" ] && echo "No workers running" || docker service ps \
		--format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" --filter "desired-state=running" \
		$(SERVICES) --filter "name=$(NAME_PREFIX)-" || true

PRG_NAME = $(NAME_PREFIX)-$*
CFG_FILE = $(CFG_DIR)/sidekiq-$*.yml

start-%:
	test -s $(CFG_FILE) || { echo "sidekiq config file not found for $*"; exit 1; } || true
	docker service create -dt --with-registry-auth --label $(PROC_LABEL) --name $(PRG_NAME) --hostname $(PRG_NAME) \
		--network $(NET) $(ENV_VARS) $(MOUNTS) --replicas 1 \
		--restart-condition on-failure --stop-signal 20 --stop-grace-period 30s \
		$(WORKER_IMAGE) sidekiq -C config/sidekiq-$*.yml -g $* -r ./worker.rb || true

halt-%:
	./service_exec $(PRG_NAME) kill -s 20 1 || true

stop-%:
	docker service rm $(PRG_NAME) || true

restart-%:
	docker service update $(PRG_NAME)

logs-%:
	./service_logs $(PRG_NAME) || true

shell-%:
	./service_exec $(PRG_NAME) bash || true
