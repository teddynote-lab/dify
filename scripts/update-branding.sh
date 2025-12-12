#!/bin/bash

#################################################################################
# Dify Branding Update Script
#
# This script helps update branding assets and restart the web container
# to ensure changes are properly reflected in the application.
#
# Usage: ./scripts/update-branding.sh [IMAGE_FILE]
#
# If IMAGE_FILE is provided, it will be copied to the branding directory.
# If not provided, you'll be prompted to manually copy your image file.
#################################################################################

set -euo pipefail

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BRANDING_DIR="docker/volumes/branding"
TARGET_FILE="profile.svg"
WEB_CONTAINER="docker-web-1"

echo -e "${BLUE}🎨 Dify Branding Update Script${NC}"
echo

# Create branding directory if it doesn't exist
mkdir -p "$BRANDING_DIR"

# Check if image file argument is provided
if [[ $# -eq 1 ]]; then
    IMAGE_FILE="$1"

    if [[ ! -f "$IMAGE_FILE" ]]; then
        echo -e "${YELLOW}⚠️  Error: File '$IMAGE_FILE' not found${NC}"
        exit 1
    fi

    echo -e "${BLUE}📁 Copying branding image...${NC}"
    cp "$IMAGE_FILE" "$BRANDING_DIR/$TARGET_FILE"
    echo -e "${GREEN}✅ Copied '$IMAGE_FILE' to '$BRANDING_DIR/$TARGET_FILE'${NC}"
else
    echo -e "${YELLOW}📋 Manual Setup Instructions:${NC}"
    echo "1. Copy your branding image (SVG recommended) to: $BRANDING_DIR/$TARGET_FILE"
    echo "2. Run this script again after copying the file"
    echo

    if [[ ! -f "$BRANDING_DIR/$TARGET_FILE" ]]; then
        echo -e "${YELLOW}⚠️  File '$BRANDING_DIR/$TARGET_FILE' not found${NC}"
        echo -e "Please copy your branding image and run: ${BLUE}$0 [your-image-file]${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Found existing branding file: $BRANDING_DIR/$TARGET_FILE${NC}"
fi

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if web container exists
if ! docker ps -a --format "{{.Names}}" | grep -q "^${WEB_CONTAINER}$"; then
    echo -e "${YELLOW}⚠️  Web container '$WEB_CONTAINER' not found.${NC}"
    echo "Please make sure Dify is running with: make up"
    exit 1
fi

# Restart web container
echo -e "${BLUE}🔄 Restarting web container to apply branding changes...${NC}"
docker restart "$WEB_CONTAINER"

# Wait for container to be ready
echo -e "${BLUE}⏳ Waiting for web container to be ready...${NC}"
sleep 5

# Test if branding file is accessible
echo -e "${BLUE}🧪 Testing branding file accessibility...${NC}"
if curl -f -s http://localhost:80/branding/profile.svg >/dev/null; then
    echo -e "${GREEN}✅ Branding file is accessible at http://localhost:80/branding/profile.svg${NC}"
else
    echo -e "${YELLOW}⚠️  Branding file test failed. Please check manually.${NC}"
fi

echo
echo -e "${GREEN}🎉 Branding update completed!${NC}"
echo
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Open your browser and go to http://localhost"
echo "2. Check if the new branding image appears in profile areas"
echo "3. If needed, clear browser cache to see changes"
echo
echo -e "${BLUE}💡 Tips:${NC}"
echo "- Use SVG format for best quality and scalability"
echo "- Keep image dimensions square for best appearance"
echo "- File should be named 'profile.svg' in the branding directory"