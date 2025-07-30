#!/bin/bash

# Script to build web image locally and run docker compose
# This ensures local changes are included in the container

set -e  # Exit on error

echo "🔨 Building web image locally (clean build with no cache)..."
docker compose build --no-cache web

if [ $? -eq 0 ]; then
    echo "✅ Web image built successfully"
    
    echo "🚀 Starting all services..."
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ All services started successfully"
        echo ""
        echo "📌 Services are running at:"
        echo "   - Web UI: http://localhost"
        echo "   - API: http://localhost/console/api"
        echo ""
        echo "💡 To view logs: docker compose logs -f"
        echo "💡 To stop services: docker compose down"
    else
        echo "❌ Failed to start services"
        exit 1
    fi
else
    echo "❌ Failed to build web image"
    exit 1
fi