#!/bin/bash
# Script to start Dify with local web development

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Dify services with local web development...${NC}"

# Change to docker directory
cd docker

# Start all services except web
echo -e "${YELLOW}Starting Docker services (excluding web)...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check if services are running
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}Docker services started successfully!${NC}"
else
    echo -e "${RED}Error: Some services failed to start${NC}"
    docker compose ps
    exit 1
fi

echo -e "${GREEN}✓ Backend services are running${NC}"
echo -e "${YELLOW}Now start the web development server:${NC}"
echo ""
echo -e "${GREEN}cd web${NC}"
echo -e "${GREEN}npm install${NC}"
echo -e "${GREEN}npm run dev${NC}"
echo ""
echo -e "${YELLOW}Services available at:${NC}"
echo -e "  - API: http://localhost:5001"
echo -e "  - Web (via nginx): http://localhost:80"
echo -e "  - Web (direct): http://localhost:3000"
echo ""
echo -e "${YELLOW}To stop services, run:${NC}"
echo -e "${GREEN}cd docker && docker compose down${NC}"