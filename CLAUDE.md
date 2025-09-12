# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- **Build Docker image locally**: `docker build -t telegram-bot-api .`
- **Run with environment file**: `docker run -d --env-file .env -p 8081:8081 telegram-bot-api`
- **Development with compose**: `docker compose up -d`
- **Build multi-arch for release**: Push a tag `vX.Y.Z` to trigger GitHub Actions release workflow

### Testing
- **Run shell tests**: `bash tests/run.sh` (tests entrypoint.sh without Docker)
- **Docker smoke test**: Triggered by GitHub Actions on tags, or run manually via workflow_dispatch

### CI/CD Workflows
- **test**: Runs on push/PR to main - executes `bash tests/run.sh`
- **docker-smoke**: Tests Docker image build and basic functionality
- **docker-release**: Multi-arch build and push to Docker Hub on version tags

## Architecture Overview

This is a dockerized wrapper for the [Telegram Bot API server](https://github.com/tdlib/telegram-bot-api). The project consists of:

### Core Components
- **Dockerfile**: Multi-stage build that compiles the Telegram Bot API server from source and creates a minimal Alpine-based runtime image
- **entrypoint.sh**: POSIX shell script that validates required environment variables and constructs command-line arguments for the Telegram Bot API binary
- **compose.yml**: Development configuration with local volumes for data persistence

### Build Process
The Dockerfile uses a two-stage build:
1. **Build stage**: Uses Alpine with build tools to compile the upstream Telegram Bot API server
2. **Runtime stage**: Minimal Alpine image with only runtime dependencies, running as non-root `botapi` user

### Configuration
The entrypoint script handles these environment variables:
- **Required**: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` (from https://my.telegram.org)
- **Optional**: `TELEGRAM_HTTP_PORT` (default: 8081), `TELEGRAM_HTTP_STAT_PORT` (default: 8082), `TELEGRAM_DIR` (default: /data), `TELEGRAM_TEMP_DIR` (default: /tmp), `TELEGRAM_LOG_FILE`, `TELEGRAM_LOCAL`

### Multi-Platform Support
- Supports `linux/amd64` and `linux/arm64` architectures
- Uses `--platform=$BUILDPLATFORM` for cross-compilation during build
- Published images are multi-arch and automatically select the correct variant

## Development Guidelines

### Shell Scripting
- Use POSIX `sh` syntax only (no bashisms in entrypoint.sh)
- Always use `set -e` for early failure detection
- Provide clear error messages with descriptive output to stderr

### Docker Best Practices
- Multi-stage builds to minimize final image size
- Non-root user execution for security
- Proper volume mounting for data persistence
- Health check considerations for the HTTP API endpoints

### Testing Strategy
- Shell script validation in `tests/run.sh` using mock binaries
- Docker smoke tests validate actual container functionality
- CI/CD ensures both local script logic and containerized behavior work correctly

### Version Management
- Version tags (`vX.Y.Z`) trigger automated multi-arch releases
- Image versioning follows the upstream Telegram Bot API version
- Labels in Dockerfile provide metadata for container registries