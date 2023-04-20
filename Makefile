image := overachieverr
commit-image-tag := commit-$(shell git rev-parse HEAD)
branch-image-tag := branch-$(shell git rev-parse --abbrev-ref HEAD | tr '/' '-')

HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
DOCKER_COMPOSE = HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker-compose

.PHONY: all
all: build run

.PHONY: run
run: build
	$(DOCKER_COMPOSE) up -d
	$(DOCKER_COMPOSE) exec ${image} bash

.PHONY: build
build:
	COMPOSE_DOCKER_CLI_BUILD=1 \
	BRANCH_IMAGE_TAG=$(branch-image-tag) \
	COMMIT_IMAGE_TAG=$(commit-image-tag) \
	$(DOCKER_COMPOSE) build \
	  --pull \
	  --progress=plain
