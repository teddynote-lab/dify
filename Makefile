# Variables
DOCKER_REGISTRY=langgenius
WEB_IMAGE=$(DOCKER_REGISTRY)/dify-web
API_IMAGE=$(DOCKER_REGISTRY)/dify-api
VERSION=latest

# Default target - show help
.DEFAULT_GOAL := help

# Backend Development Environment Setup
.PHONY: dev-setup prepare-docker prepare-web prepare-api dev dev-stop dev-logs dev-restart

# Development server - run backend in Docker, frontend locally
dev:
	@echo "🚀 Starting Dify development environment..."
	@echo "📦 Starting backend services with Docker..."
	@cd docker && docker compose up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 5
	@echo "🌐 Starting frontend development server locally..."
	@cd web && pnpm dev

# Stop development Docker services
dev-stop:
	@echo "🛑 Stopping Docker services..."
	@cd docker && docker compose down
	@echo "✅ Docker services stopped"

# Show logs for Docker services
dev-logs:
	@cd docker && docker compose logs -f

# Restart Docker services
dev-restart:
	@echo "♻️ Restarting Docker services..."
	@cd docker && docker compose restart
	@echo "✅ Docker services restarted"

# Dev setup target
dev-setup: prepare-docker prepare-web prepare-api
	@echo "✅ Backend development environment setup complete!"

# Step 1: Prepare Docker middleware
prepare-docker:
	@echo "🐳 Setting up Docker middleware..."
	@cp -n docker/middleware.env.example docker/middleware.env 2>/dev/null || echo "Docker middleware.env already exists"
	@cd docker && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p dify-middlewares-dev up -d
	@echo "✅ Docker middleware started"

# Step 2: Prepare web environment
prepare-web:
	@echo "🌐 Setting up web environment..."
	@cp -n web/.env.example web/.env 2>/dev/null || echo "Web .env already exists"
	@cd web && pnpm install
	@cd web && pnpm build
	@echo "✅ Web environment prepared (not started)"

# Step 3: Prepare API environment
prepare-api:
	@echo "🔧 Setting up API environment..."
	@cp -n api/.env.example api/.env 2>/dev/null || echo "API .env already exists"
	@cd api && uv sync --dev
	@cd api && uv run flask db upgrade
	@echo "✅ API environment prepared (not started)"

# Clean dev environment
dev-clean:
	@echo "⚠️  Stopping Docker containers..."
	@cd docker && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p dify-middlewares-dev down
	@echo "🗑️  Removing volumes..."
	@rm -rf docker/volumes/db
	@rm -rf docker/volumes/redis
	@rm -rf docker/volumes/plugin_daemon
	@rm -rf docker/volumes/weaviate
	@rm -rf api/storage
	@echo "✅ Cleanup complete"

# Backend Code Quality Commands
format:
	@echo "🎨 Running ruff format..."
	@uv run --project api --dev ruff format ./api
	@echo "✅ Code formatting complete"

check:
	@echo "🔍 Running ruff check..."
	@uv run --project api --dev ruff check ./api
	@echo "✅ Code check complete"

lint:
	@echo "🔧 Running ruff format, check with fixes, and import linter..."
	@uv run --project api --dev sh -c 'ruff format ./api && ruff check --fix ./api'
	@uv run --directory api --dev lint-imports
	@echo "✅ Linting complete"

type-check:
	@echo "📝 Running type check with basedpyright..."
	@uv run --directory api --dev basedpyright
	@echo "✅ Type check complete"

# Build Docker images
build-web:
	@echo "Building web Docker image: $(WEB_IMAGE):$(VERSION)..."
	docker build -t $(WEB_IMAGE):$(VERSION) ./web
	@echo "Web Docker image built successfully: $(WEB_IMAGE):$(VERSION)"

build-api:
	@echo "Building API Docker image: $(API_IMAGE):$(VERSION)..."
	docker build -t $(API_IMAGE):$(VERSION) ./api
	@echo "API Docker image built successfully: $(API_IMAGE):$(VERSION)"

# Push Docker images
push-web:
	@echo "Pushing web Docker image: $(WEB_IMAGE):$(VERSION)..."
	docker push $(WEB_IMAGE):$(VERSION)
	@echo "Web Docker image pushed successfully: $(WEB_IMAGE):$(VERSION)"

push-api:
	@echo "Pushing API Docker image: $(API_IMAGE):$(VERSION)..."
	docker push $(API_IMAGE):$(VERSION)
	@echo "API Docker image pushed successfully: $(API_IMAGE):$(VERSION)"

# Build all images
build-all: build-web build-api

# Push all images
push-all: push-web push-api

build-push-api: build-api push-api
build-push-web: build-web push-web

# Build and push all images
build-push-all: build-all push-all
	@echo "All Docker images have been built and pushed."

# Help target
help:
	@echo "Development Setup Targets:"
	@echo "  make dev            - Start backend in Docker, frontend locally"
	@echo "  make dev-stop       - Stop Docker services"
	@echo "  make dev-logs       - Show Docker services logs"
	@echo "  make dev-restart    - Restart Docker services"
	@echo "  make dev-setup      - Run all setup steps for backend dev environment"
	@echo "  make prepare-docker - Set up Docker middleware"
	@echo "  make prepare-web    - Set up web environment"
	@echo "  make prepare-api    - Set up API environment"
	@echo "  make dev-clean      - Stop Docker middleware containers"
	@echo ""
	@echo "Backend Code Quality:"
	@echo "  make format         - Format code with ruff"
	@echo "  make check          - Check code with ruff"
	@echo "  make lint           - Format and fix code with ruff"
	@echo "  make type-check     - Run type checking with basedpyright"
	@echo ""
	@echo "Docker Build Targets:"
	@echo "  make build-web      - Build web Docker image"
	@echo "  make build-api      - Build API Docker image"
	@echo "  make build-all      - Build all Docker images"
	@echo "  make push-all       - Push all Docker images"
	@echo "  make build-push-all - Build and push all Docker images"

# Phony targets
.PHONY: build-web build-api push-web push-api build-all push-all build-push-all dev-setup prepare-docker prepare-web prepare-api dev-clean help format check lint type-check
