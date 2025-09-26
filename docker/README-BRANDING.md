# Docker Setup with Custom Branding

This setup allows you to run Dify with custom branding using Docker Compose.

## Quick Start

1. **Setup branding assets**:
   ```bash
   make setup-branding
   ```

2. **Add your branding files**:
   - Place your logo at: `docker/volumes/branding/logo.png`
   - Place your profile image at: `docker/volumes/branding/profile.png`

3. **Configure environment variables** (optional):

   Create or edit `docker/.env` file:
   ```env
   # Branding Configuration
   NEXT_PUBLIC_BRAND_NAME=DashFlow
   NEXT_PUBLIC_BRAND_URL=https://dashflow.studio/
   NEXT_PUBLIC_LOGO_PATH=/branding/logo.png
   NEXT_PUBLIC_PROFILE_PATH=/branding/profile.png
   ```

4. **Build and run**:
   ```bash
   make build
   make up
   ```

5. **Access Dify**:
   Open http://localhost in your browser

## Available Commands

```bash
make build          # Build all Docker images locally
make up             # Start all services
make down           # Stop all services
make restart        # Restart all services
make logs           # View logs from all services
make ps             # Show running containers
make clean          # Clean up volumes and containers
make setup-branding # Setup branding directory structure
```

## Files Structure

```
docker/
├── docker-compose.yaml           # Main Docker Compose file
├── docker-compose.override.yaml  # Override with local builds and branding
├── Makefile                      # Convenience commands
├── nginx/
│   └── conf.d/
│       └── default-local-dev.conf  # Nginx configuration for local dev
└── volumes/
    └── branding/                 # Your branding assets
        ├── logo.png              # Your brand logo
        └── profile.png           # Default profile image
```

## Customization

### Branding Environment Variables

- `NEXT_PUBLIC_BRAND_NAME`: Your brand name (default: "DashFlow")
- `NEXT_PUBLIC_BRAND_URL`: Your brand URL (default: "https://dashflow.studio/")
- `NEXT_PUBLIC_LOGO_PATH`: Path to logo file (default: "/branding/logo.png")
- `NEXT_PUBLIC_PROFILE_PATH`: Path to profile image (default: "/branding/profile.png")

### Using Different Branding Per Environment

You can create multiple `.env` files for different environments:

```bash
# Development
cp docker/.env.example docker/.env.dev
# Production
cp docker/.env.example docker/.env.prod
```

Then use them with Docker Compose:

```bash
docker compose --env-file .env.dev -f docker-compose.yaml -f docker-compose.override.yaml up
```

## Troubleshooting

### Branding not showing up
1. Ensure branding files exist in `docker/volumes/branding/`
2. Check that the web service has restarted: `make restart`
3. Clear browser cache

### Permission issues
If you encounter permission issues with volumes:
```bash
sudo chown -R $USER:$USER docker/volumes/branding
```

### Build failures
If builds fail, try cleaning and rebuilding:
```bash
make clean
make build
```