APP_NAME := image-webp-service
PORT := 3000
FILES_DIR := $(PWD)/files

.PHONY: build run docker-build docker-run clean

## 🧱 Build the Go app (native)
build:
	CGO_ENABLED=1 go build -o app main.go

## 🚀 Run locally (native)
run:
	@mkdir -p files
	PORT=$(PORT) ./app

## 🐳 Build Docker image
docker-build:
	docker build -t $(APP_NAME) .

## 🐳 Run Docker container
docker-run:
	docker run --rm -p $(PORT):3000 \
		-v $(FILES_DIR):/app/files \
		--name $(APP_NAME) \
		$(APP_NAME)

## 🧹 Clean built binary
clean:
	rm -f app
