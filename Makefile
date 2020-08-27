CMD=lazy-chat
BINARY=lazy-chat
ROOT_DIR := $(if $(ROOT_DIR),$(ROOT_DIR),$(shell git rev-parse --show-toplevel))
BUILD_DIR = $(ROOT_DIR)/build
all: build

build: clean
	mkdir -p $(BUILD_DIR)
	go install ./cmd/$(CMD)/*
	GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY) ./cmd/$(CMD)

docker: build
	docker build -t habakke/lazy-chat:latest .
	docker push habakke/lazy-chat

docker-run: docker
	docker run -p 8080:8080 habakke/lazy-chat

start:
	go run $(ROOT_DIR)/cmd/$(CMD)

clean:
	rm -rf $(BUILD_DIR)
