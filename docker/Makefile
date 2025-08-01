.PHONY: build up down logs ps

# Build all local images
build:
	@echo "Building API image..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml build api
	@echo "Building Web image..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml build web
	@echo "All images built successfully!"

# Start all services
up:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
	@echo "All services started!"

# Stop all services
down:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
	@echo "All services stopped!"

# View logs
logs:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml logs -f

# Show running containers
ps:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml ps