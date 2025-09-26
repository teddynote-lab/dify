.PHONY: build up down logs ps restart clean

# Build all local images
build:
	@echo "🔨 Building API image..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml build api
	@echo "🔨 Building Web image..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml build web
	@echo "✅ All images built successfully!"

# Start all services
up:
	@echo "🚀 Starting all services..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml up -d
	@echo "✅ All services started!"
	@echo "📌 Access Dify at: http://localhost"

# Stop all services
down:
	@echo "🛑 Stopping all services..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml down
	@echo "✅ All services stopped!"

# View logs
logs:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml logs -f

# Show running containers
ps:
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml ps

# Restart all services
restart: down up
	@echo "♻️ All services restarted!"

# Clean up volumes and rebuild
clean:
	@echo "🧹 Cleaning up volumes and containers..."
	docker compose -f docker-compose.yaml -f docker-compose.override.yaml down -v
	@echo "✅ Cleanup complete!"

# Development setup with branding
setup-branding:
	@echo "📁 Setting up branding directory..."
	@mkdir -p volumes/branding
	@echo "⚠️  Please add the following files to docker/volumes/branding/:"
	@echo "   - logo.png (your brand logo)"
	@echo "   - profile.png (default profile image)"
	@echo ""
	@echo "🔧 You can also customize branding by setting these in your .env file:"
	@echo "   NEXT_PUBLIC_BRAND_NAME=YourBrand"
	@echo "   NEXT_PUBLIC_BRAND_URL=https://yourbrand.com/"
	@echo "   NEXT_PUBLIC_LOGO_PATH=/branding/logo.png"
	@echo "   NEXT_PUBLIC_PROFILE_PATH=/branding/profile.png"