include .env
export

.SILENT:

.PHONY: help restart

define HELPTEXT

	Usage make queue_<command>

	commands:
	    restart             restart the queue service

endef

UID ?= 210
GID ?= 210

help:
	$(info $(HELPTEXT))

restart:
	docker service update $(SERVICE)
