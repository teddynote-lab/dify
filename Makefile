# Variables
DOCKER_REGISTRY=langgenius
WEB_IMAGE=$(DOCKER_REGISTRY)/dify-web
API_IMAGE=$(DOCKER_REGISTRY)/dify-api
VERSION=latest

# Build Docker images
build-web:
	@echo "Building web Docker image with no-cache..."
	cd docker && docker compose build --no-cache web
	@echo "Web Docker image built successfully"

build-api:
	@echo "Building API Docker image with no-cache..."
	cd docker && docker compose build --no-cache api worker worker_beat
	@echo "API Docker image built successfully"

# Build all images
build: build-web build-api

# Start services
up:
	@echo "Starting Dify services..."
	cd docker && docker compose up -d
	@echo "Dify services started successfully"

# Stop services
down:
	@echo "Stopping Dify services..."
	cd docker && docker compose down
	@echo "Dify services stopped successfully"

# Phony targets
.PHONY: build-web build-api build-all up down
