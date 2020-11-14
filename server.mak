include .env
export

.SILENT:

.PHONY: build

define HELPTEXT

	Usage make server_<command>	: manage $(SERVICE) application

	commands:
		build:          build the docker image
		publish:        publish the image to the registry
		shell:          interactive bash shell
		gems_install:   install gems
		gems_update:    update gems
		db_migrate:     migrate database
		db_seed:        seed database

endef

SERVER_IMAGE ?= registry.docker.libis.be/teneo/ingest_server
UID ?= $(shell id -u)
GID ?= $(shell id -g)

help:
	$(info $(HELPTEXT))

collect:
	tar -cf server.tar --owner=$(UID) --group=$(GID) \
		--exclude=db/migrate --exclude=db/seeds*  --exclude=lib/teneo/ingester* \
		Gemfile Rakefile server.rb bin config db lib

build: collect
	docker build --tag $(SERVER_IMAGE) --build-arg UID=$(UID) --build-arg GID=$(GID) -f Dockerfile.server .

publish:
	docker push $(SERVER_IMAGE)

VOLUMES := -v ${PWD}/bundle:/bundle-gems -v ${ORACLE_CLIENT}:/oracle-client -v ${PWD}/.env:/ingest/.env \
-v ${PWD}/Gemfile:/ingest/Gemfile -v ${PWD}/Gemfile.lock:/ingest/Gemfile.lock -v ${PWD}/Rakefile:/ingest/Rakefile \
-v ${PWD}/config:/ingest/config -v ${PWD}/server.rb:/ingest/server.rb -v ${PWD}/db:/ingest/db -v ${PWD}/lib:/ingest/lib

shell:
	docker run --rm -it --network $(NET) $(VOLUMES) $(SERVER_IMAGE) bash

gems_install:
	docker run --rm -it --network $(NET) $(VOLUMES) $(SERVER_IMAGE) bundle install

gems_update:
	docker run --rm -it --network $(NET) $(VOLUMES) $(SERVER_IMAGE) bundle update
