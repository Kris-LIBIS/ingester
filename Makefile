include .env
export

define HELPTEXT
	usage: make <command>

	commands:
	    status              show running services in this stack
	    up                  (re)deploy the ingester application
	    down                stop and remove the application
	    restart             stop and restart the application
	    clean               stop the application and remove all data
endef

.SILENT:

help:
	$(info $(HELPTEXT))
	make database_help
	make queue_help
	make worker_help

UID := $(shell id -u)
GID := $(shell id -g)

STACK := ingester
NETWORK := $(STACK)_net
DB_SERVICE := $(STACK)_db
QUEUE_SERVICE := $(STACK)_redis
API_SERVICE := $(STACK)_api
WORKER_SERVICE := $(STACK)_worker

FORCE:

status:
	docker stack ps $(STACK) --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}"

up:
	USER_ID=$(UID) GROUP_ID=$(GID) docker stack deploy --with-registry-auth -c docker-stack.yml $(STACK)

down:
	docker stack down $(STACK)
	while docker stack ls | grep $(STACK) > /dev/null; do echo -n .; sleep 1; done
	while docker network ls | grep $(NETWORK) > /dev/null; do echo -n .; sleep 1; done
	echo ''

restart: down up

clean: down
	rm -fr database/postgres/db || true
	rm -fr database/redis/data/* || true
	rm -fr bundle/* || true

stats:
	docker stats --format "table {{.Name}}\t{{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}"

database_%:
	SERVICE=$(DB_SERVICE) UID=$(UID) GID=$(GID) make -f database.mak $(MAKEFILE_LIST) $*

queue_%:
	SERVICE=$(DB_SERVICE) UID=$(UID) GID=$(GID) make -f queue.mak $(MAKEFILE_LIST) $*

worker_%:
	SERVICE=$(WORKER_SERVICE) QUEUE=$(QUEUE_SERVICE) NET=$(NETWORK) UID=$(UID) GID=$(GID) make -f worker.mak $(MAKEFILE_LIST) $*
