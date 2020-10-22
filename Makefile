ifndef VERBOSE
.SILENT:
endif

# set default shell
SHELL=/bin/bash -o pipefail -o errexit

DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
INIT_BUILDX=$(DIR)/contrib/init-buildx.sh

TAG ?= latest
NS  ?= openfaas

GIT_COMMIT_MESSAGE?=$(git log -1 --pretty=%B 2>&1 | head -n 1)
GIT_COMMIT_SHA?=$(git rev-list -1 HEAD)
VERSION?=$(git describe --all --exact-match `git rev-parse HEAD` | grep tags | sed 's/tags\///' || echo dev)

PLATFORMS?=linux/amd64,linux/arm64
OUTPUT=
PROGRESS=plain

all: build

local:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o faas-netes

build: ensure-buildx
	docker buildx build \
	--platform=${PLATFORMS} $(OUTPUT) \
	--progress=$(PROGRESS) \
	--pull \
	--build-arg https_proxy=$(https_proxy) --build-arg http_proxy=$(http_proxy) \
	--build-arg GIT_COMMIT_MESSAGE="$(GIT_COMMIT_MESSAGE)" \
	--build-arg GIT_COMMIT_SHA="$(GIT_COMMIT_SHA)" \
	--build-arg VERSION="$(VERSION:-dev)" \
	-t $(NS)/faas-netes:$(TAG) .

# push the cross built image
push: OUTPUT=--push
push: build

# enable buildx
ensure-buildx:
	@exec $(INIT_BUILDX)

namespaces:
	kubectl apply -f namespaces.yml

install: namespaces
	kubectl apply -f yaml/

charts:
	cd chart && helm package openfaas/ && helm package kafka-connector/ && helm package cron-connector/ && helm package nats-connector/ && helm package mqtt-connector/
	mv chart/*.tgz docs/
	helm repo index docs --url https://openfaas.github.io/faas-netes/ --merge ./docs/index.yaml
	./contrib/create-static-manifest.sh
	./contrib/create-static-manifest.sh ./chart/openfaas ./yaml_arm64 ./chart/openfaas/values-arm64.yaml
	./contrib/create-static-manifest.sh ./chart/openfaas ./yaml_armhf ./chart/openfaas/values-armhf.yaml

start-kind: ## attempt to start a new dev environment
	@./contrib/create_dev.sh \
		&& echo "" \
		&& printf '%-15s:\t %s\n' 'Web UI' 'http://localhost:31112/ui' \
		&& printf '%-15s:\t %s\n' 'User' 'admin' \
		&& printf '%-15s:\t %s\n' 'Password' $(shell cat password.txt) \
		&& printf '%-15s:\t %s\n' 'CLI Login' "faas-cli login --username admin --password $(shell cat password.txt)"

stop-kind: ## attempt to stop the dev environment
	@./contrib/stop_dev.sh

.PHONY: all build local build-arm64 build-armhf push namespaces install install-armhf charts ensure-buildx start-kind stop-kind
