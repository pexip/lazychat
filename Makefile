CMD=lazy-chat
BINARY=lazy-chat
ROOT_DIR := $(if $(ROOT_DIR),$(ROOT_DIR),$(shell git rev-parse --show-toplevel))
BUILD_DIR = $(ROOT_DIR)/build
all: build

build: clean
	mkdir -p $(BUILD_DIR)
	go install ./cmd/$(CMD)/*
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY) ./cmd/$(CMD)

docker: build
	docker build -t gcr.io/px-sre-homework/lazy-chat:latest .

push: docker
	docker push gcr.io/px-sre-homework/lazy-chat:latest

docker-run: docker
	docker run -p 8080:8080 -d --read-only --tmpfs /run --tmpfs /tmp gcr.io/px-sre-homework/lazy-chat

start:
	go run $(ROOT_DIR)/cmd/$(CMD)

clean:
	rm -rf $(BUILD_DIR)
