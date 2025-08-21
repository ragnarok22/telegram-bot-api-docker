# Repository Guidelines

## Project Structure & Module Organization
- `Dockerfile`: Multi-stage build for the Telegram Bot API server.
- `entrypoint.sh`: POSIX shell startup script; parses env and launches binary.
- `compose.yml`: Local development with volumes/ports.
- `tests/`: Shell tests for `entrypoint.sh` (`tests/run.sh`).
- `.github/workflows/`: CI for tests, multi-arch release, and Docker smoke.
- `README.md`: Usage and environment variables.

## Build, Test, and Development Commands
- Build image (local): `docker build -t telegram-bot-api:dev .`
- Run locally: `docker run -d --env-file .env -p 8081:8081 telegram-bot-api:dev`
- Compose: `docker compose up -d`
- Entry script tests: `bash tests/run.sh`
- Docker smoke (manual or on tags): GitHub Actions workflow `docker-smoke`.
- Release (multi-arch): push a tag `vX.Y.Z` to trigger `.github/workflows/docker-release.yml`.

## Coding Style & Naming Conventions
- Shell: POSIX `sh` only (avoid bashisms). Prefer `set -e` and clear error messages.
- Indentation: 2 spaces; wrap long lines thoughtfully.
- Env vars: `UPPER_SNAKE_CASE` (e.g., `TELEGRAM_HTTP_PORT`).
- Filenames: lowercase with dashes or underscores (e.g., `entrypoint.sh`).
- Keep scripts executable and minimal; fail fast on invalid config.

## Testing Guidelines
- Framework: simple POSIX shell assertions in `tests/run.sh`.
- What to test: required env validation, default args, custom flags, passthrough exec.
- Run locally: `bash tests/run.sh` (no Docker required; uses a mock binary).
- CI: `test` workflow runs on push/PR to `main`. Extend tests when adding new env flags.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `ci:`, `docs:`, `test:`, etc.
- PRs include: concise description, motivation, test output, and docs updates (README/compose) when behavior changes.
- Link related issues and reference user-impacting changes.

## Security & Configuration Tips
- Never commit secrets; use `.env` and keep it out of VCS (see `.dockerignore`).
- Required: `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`.
- Apple Silicon: image is multi-arch. If needed, run with `--platform linux/arm64/v8`.
- Publishing requires `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` GitHub secrets.

