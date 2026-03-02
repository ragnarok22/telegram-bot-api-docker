# Repository Guidelines

## Project Structure & Module Organization
- `Dockerfile`: Multi-stage build for the Telegram Bot API server.
- `entrypoint.sh`: POSIX shell startup script; parses env and launches binary.
- `compose.yml`: Local development with volumes/ports.
- `tests/`: Shell tests for `entrypoint.sh` (`tests/run.sh`).
- `.github/workflows/`: CI for tests, multi-arch release, and Docker smoke.
- `README.md`: Usage and environment variables.

## Architecture Overview
This repository is a Docker wrapper around the upstream [Telegram Bot API server](https://github.com/tdlib/telegram-bot-api).

### Build Process
The Dockerfile uses two stages:
1. Build stage: Alpine + toolchain compiles the upstream server from source.
2. Runtime stage: minimal Alpine image with runtime deps, running as non-root `botapi`.

### Configuration Model
- Required env vars: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`.
- Optional env vars: `TELEGRAM_HTTP_PORT` (default `8081`), `TELEGRAM_HTTP_STAT_PORT` (default `8082`), `TELEGRAM_DIR` (default `/data`), `TELEGRAM_TEMP_DIR` (default `/tmp`), `TELEGRAM_LOG_FILE`, `TELEGRAM_LOCAL`.

### Multi-Platform Support
- Targets `linux/amd64` and `linux/arm64`.
- Uses `--platform=$BUILDPLATFORM` during build stage.
- Release image is multi-arch and selects the correct variant automatically.

## Build, Test, and Development Commands
- Build image (local): `docker build -t telegram-bot-api:dev .`
- Run locally: `docker run -d --env-file .env -p 8081:8081 telegram-bot-api:dev`
- Compose: `docker compose up -d`
- Entry script tests: `bash tests/run.sh`
- Docker smoke (manual or on tags): GitHub Actions workflow `docker-smoke`.
- Release (multi-arch): push a tag `vX.Y` or `vX.Y.Z` to trigger `.github/workflows/docker-release.yml`.

## CI/CD Workflows
- `test`: runs on push/PR to `main`, executes `bash tests/run.sh`.
- `docker-smoke`: builds/tests container behavior.
- `docker-release`: runs smoke, then publishes multi-arch image to Docker Hub on matching version tags.

## Coding Style & Naming Conventions
- Shell: POSIX `sh` only (avoid bashisms). Prefer `set -e` and clear error messages.
- Indentation: 2 spaces; wrap long lines thoughtfully.
- Env vars: `UPPER_SNAKE_CASE` (for example, `TELEGRAM_HTTP_PORT`).
- Filenames: lowercase with dashes or underscores (for example, `entrypoint.sh`).
- Keep scripts executable and minimal; fail fast on invalid config.

## Docker & Runtime Practices
- Keep Docker builds multi-stage to minimize runtime size.
- Keep runtime as non-root user.
- Use persistent volumes for data/logs.
- Keep health checks aligned with HTTP API readiness.

## Testing Guidelines
- Framework: simple POSIX shell assertions in `tests/run.sh`.
- What to test: required env validation, default args, custom flags, passthrough exec.
- Run locally: `bash tests/run.sh` (no Docker required; uses a mock binary).
- CI: `test` workflow runs on push/PR to `main`. Extend tests when adding new env flags.

## Versioning Guidance
- Use version tags to trigger automated release publishing.
- Keep image metadata labels in `Dockerfile` synchronized with the intended release version.
- Image versioning should follow the upstream Telegram Bot API version.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `ci:`, `docs:`, `test:`, etc.
- PRs include: concise description, motivation, test output, and docs updates (`README.md`/`compose.yml`) when behavior changes.
- Link related issues and reference user-impacting changes.

## Security & Configuration Tips
- Never commit secrets; use `.env` and keep it out of VCS (see `.dockerignore`).
- Required runtime secrets: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`.
- Apple Silicon: image is multi-arch. If needed, run with `--platform linux/arm64/v8`.
- Publishing requires `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` GitHub secrets.
