GO111MODULE=on

CURL_BIN ?= curl
GO_BIN ?= go
GORELEASER_BIN ?= goreleaser

PUBLISH_PARAM?=
GO_MOD_PARAM?=-mod vendor
TMP_DIR?=./tmp

BASE_DIR=$(shell pwd)

NAME=goclitem

export GO111MODULE=on
export GOPROXY=https://proxy.golang.org
export PATH := $(BASE_DIR)/bin:$(PATH)

install:
	$(GO_BIN) install -v ./cmd/$(NAME)

build:
	$(GO_BIN) build -v ./cmd/$(NAME)

clean:
	rm -f $(NAME)
	rm -rf dist/
	rm -rf cmd/$(NAME)/dist

clean-deps:
	rm -rf ./bin
	rm -rf ./tmp
	rm -rf ./libexec
	rm -rf ./share

./bin/bats:
	git clone https://github.com/bats-core/bats-core.git ./tmp/bats
	./tmp/bats/install.sh .

./bin/golangci-lint:
	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s v1.22.2

./bin/tparse: ./bin ./tmp
	curl -sfL -o ./tmp/tparse.tar.gz https://github.com/mfridman/tparse/releases/download/v0.7.4/tparse_0.7.4_Linux_x86_64.tar.gz
	tar -xf ./tmp/tparse.tar.gz -C ./bin

test-deps: ./bin/tparse ./bin/bats ./bin/golangci-lint
	$(GO_BIN) get github.com/mfridman/tparse
	$(GO_BIN) install github.com/mfridman/tparse
	$(GO_BIN) get -v ./...
	$(GO_BIN) mod tidy

./bin:
	mkdir ./bin

./tmp:
	mkdir ./tmp

./bin/goreleaser: ./bin ./tmp
	$(CURL_BIN) --fail -L -o ./tmp/goreleaser.tar.gz https://github.com/goreleaser/goreleaser/releases/download/v0.124.1/goreleaser_Linux_x86_64.tar.gz
	gunzip -f ./tmp/goreleaser.tar.gz
	tar -C ./bin -xvf ./tmp/goreleaser.tar

build-deps: ./bin/goreleaser

deps: build-deps test-deps

test:
	$(GO_BIN) test -json ./... | tparse -all

acceptance-test:
	bats --tap test/*.bats

ci-test:
	$(GO_BIN) test -race -coverprofile=coverage.txt -covermode=atomic -json ./... | tparse -all

lint:
	golangci-lint run

release: clean
	cd cmd/$(NAME) ; $(GORELEASER_BIN) $(PUBLISH_PARAM)

update:
	$(GO_BIN) get -u
	$(GO_BIN) mod tidy
	make test
	make install
	$(GO_BIN) mod tidy

.PHONY: install build clean clean-deps test-deps build-deps deps test acceptance-test ci-test lint release update

