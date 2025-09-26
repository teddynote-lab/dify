# Makefile for Dify

# Variables
DOCKER_DIR = docker
WEB_DIR = web
API_DIR = api

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target - show help
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help:
	@echo "$(BLUE)Dify Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Primary Commands:$(NC)"
	@echo "  make down              - Stop all Docker containers"
	@echo "  make build             - Clean build all local Docker images"
	@echo "  make up                - Start all Docker services"
	@echo "  make dev               - Start Docker services (except web) and run frontend locally"
	@echo ""
	@echo "$(YELLOW)Code Quality Commands:$(NC)"
	@echo "  make lint              - Run linters for backend and frontend"
	@echo "  make type-check        - Run type checking"
	@echo "  make format            - Format code"

# Primary Commands
.PHONY: down
down:
	@echo "$(RED)⏹ Stopping all Docker services...$(NC)"
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.yaml -f docker-compose.override.yaml down

.PHONY: build
build:
	@echo "$(BLUE)🔨 Clean building all Docker images...$(NC)"
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.yaml -f docker-compose.override.yaml build --no-cache api worker worker_beat web

.PHONY: up
up:
	@echo "$(GREEN)🚀 Starting all Docker services...$(NC)"
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
	@echo "$(GREEN)✅ All services are running!$(NC)"
	@echo "$(BLUE)📌 Access Dify at: http://localhost$(NC)"

.PHONY: dev
dev:
	@echo "$(GREEN)🚀 Starting development environment...$(NC)"
	@echo "$(BLUE)1️⃣ Starting Docker services (except web)...$(NC)"
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d api worker worker_beat db redis nginx weaviate sandbox ssrf_proxy
	@echo "$(BLUE)2️⃣ Waiting for services to be ready...$(NC)"
	@sleep 5
	@echo "$(BLUE)3️⃣ Starting frontend development server...$(NC)"
	@cd $(WEB_DIR) && pnpm dev

# Code Quality Commands
.PHONY: lint
lint:
	@echo "$(YELLOW)🔍 Running linters...$(NC)"
	@echo "$(BLUE)Backend linting...$(NC)"
	@cd $(API_DIR) && uv run --project . ruff check ./
	@echo "$(BLUE)Frontend linting...$(NC)"
	@cd $(WEB_DIR) && pnpm lint

.PHONY: type-check
type-check:
	@echo "$(YELLOW)📝 Running type checking...$(NC)"
	@echo "$(BLUE)Backend type checking...$(NC)"
	@cd $(API_DIR) && uv run --directory . basedpyright
	@echo "$(BLUE)Frontend type checking...$(NC)"
	@cd $(WEB_DIR) && pnpm type-check

.PHONY: format
format:
	@echo "$(YELLOW)✨ Formatting code...$(NC)"
	@echo "$(BLUE)Backend formatting...$(NC)"
	@cd $(API_DIR) && uv run --project . ruff check --fix ./
	@cd $(API_DIR) && uv run --project . ruff format ./
	@echo "$(BLUE)Frontend formatting...$(NC)"
	@cd $(WEB_DIR) && pnpm lint:fix