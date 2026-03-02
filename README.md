# Telegram Bot API Dockerized

![Dockerized Telegram Bot API](https://github.com/ragnarok22/telegram-bot-api-docker/assets/8838803/546002cc-ab83-494e-8c57-c1e5d18246c9)

![Docker Image Version](https://img.shields.io/docker/v/ragnarok22/telegram-bot-api-docker)
![Docker Pulls](https://img.shields.io/docker/pulls/ragnarok22/telegram-bot-api-docker)
![Docker Image Size](https://img.shields.io/docker/image-size/ragnarok22/telegram-bot-api-docker)
[![test](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/test.yml/badge.svg)](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/test.yml)
[![docker-release](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/docker-release.yml/badge.svg)](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/docker-release.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ragnarok22/telegram-bot-api-docker)

Dockerized [Telegram Bot API](https://github.com/tdlib/telegram-bot-api) server with a minimal Alpine runtime image and a configurable entrypoint.

## Table of Contents
- [Quick Start](#quick-start)
- [Docker Compose](#docker-compose)
- [Environment Variables](#environment-variables)
- [Usage](#usage)
- [Apple Silicon and ARM64](#apple-silicon-and-arm64)
- [Development](#development)
- [CI/CD and Release](#cicd-and-release)
- [Troubleshooting](#troubleshooting)
- [Switching from api.telegram.org](#switching-from-apitelegramorg)
- [Moving Between Local Servers](#moving-between-local-servers)
- [Documentation](#documentation)
- [License](#license)

## Quick Start

1. Install [Docker](https://docs.docker.com/get-docker/).
2. Pull the image:
   ```bash
   docker pull ragnarok22/telegram-bot-api-docker
   ```
3. Create `.env`:
   ```bash
   TELEGRAM_API_ID=12345
   TELEGRAM_API_HASH=1234567890abcdef1234567890abcdef
   # Optional overrides:
   # TELEGRAM_HTTP_PORT=8081
   # TELEGRAM_HTTP_STAT_PORT=8082
   # TELEGRAM_DIR=/data
   # TELEGRAM_TEMP_DIR=/tmp
   # TELEGRAM_LOG_FILE=/data/logs/telegram-bot-api.log
   # TELEGRAM_LOCAL=true
   # TELEGRAM_EXTRA_ARGS=--max-webhook-connections 80
   ```
   Get credentials from https://my.telegram.org.
4. Start the container:
   ```bash
   docker run -d --name telegram-bot-api \
     --env-file .env \
     -p 8081:8081 -p 8082:8082 \
     -v "$(pwd)/data:/data" \
     ragnarok22/telegram-bot-api-docker
   ```
5. Verify:
   ```bash
   curl http://localhost:8081/bot<TOKEN>/getMe
   ```

The default log file is `/data/logs/telegram-bot-api.log` inside the container.

## Docker Compose

This repository includes [compose.yml](compose.yml), which builds from the local `Dockerfile`:

```bash
docker compose up -d --build
```

Compose service details:
- service name: `telegram-api`
- ports: `8081` (API), `8082` (statistics)
- mounted volume: `./data:/data`
- env file: `.env`

If you prefer using the published image directly, use this minimal compose snippet:

```yaml
services:
  telegram-bot-api:
    image: ragnarok22/telegram-bot-api-docker
    env_file: .env
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - ./data:/data
```

## Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `TELEGRAM_API_ID` | Yes | - | API ID from https://my.telegram.org |
| `TELEGRAM_API_HASH` | Yes | - | API hash from https://my.telegram.org |
| `TELEGRAM_HTTP_PORT` | No | `8081` | HTTP API listen port |
| `TELEGRAM_HTTP_STAT_PORT` | No | `8082` | HTTP statistics port |
| `TELEGRAM_DIR` | No | `/data` | Bot data directory |
| `TELEGRAM_TEMP_DIR` | No | `/tmp` | Temp directory for HTTP files |
| `TELEGRAM_LOG_FILE` | No | `/data/logs/telegram-bot-api.log` | Log file path |
| `TELEGRAM_LOCAL` | No | disabled | Enable `--local` mode with `1` or `true` |
| `TELEGRAM_EXTRA_ARGS` | No | empty | Extra flags passed verbatim to `telegram-bot-api` |

## Usage

Run with defaults:

```bash
docker run -d --env-file .env -p 8081:8081 -p 8082:8082 ragnarok22/telegram-bot-api-docker
```

Run with custom ports and local mode:

```bash
docker run -d --env-file .env \
  -e TELEGRAM_HTTP_PORT=9000 \
  -e TELEGRAM_HTTP_STAT_PORT=9001 \
  -e TELEGRAM_LOCAL=true \
  -p 9000:9000 -p 9001:9001 \
  ragnarok22/telegram-bot-api-docker
```

Pass through additional upstream flags:

```bash
docker run -d --env-file .env \
  -e TELEGRAM_EXTRA_ARGS="--max-webhook-connections 50 --log-verbosity-level 3" \
  -p 8081:8081 -p 8082:8082 \
  ragnarok22/telegram-bot-api-docker
```

Bypass default startup logic and execute a custom command:

```bash
docker run --rm ragnarok22/telegram-bot-api-docker ./telegram-bot-api --version
```

## Apple Silicon and ARM64

The image is multi-arch (`linux/amd64`, `linux/arm64`), so Docker usually picks the correct variant automatically.

Build locally on Apple Silicon:

```bash
docker build -t telegram-bot-api:dev .
```

If you need to force a platform at runtime:

```bash
docker run --rm --platform linux/arm64/v8 ragnarok22/telegram-bot-api-docker ./telegram-bot-api --version
```

## Development

- Build local image: `docker build -t telegram-bot-api:dev .`
- Run entrypoint tests: `bash tests/run.sh`
- Run compose stack from source: `docker compose up -d --build`

## CI/CD and Release

GitHub Actions workflows:
- `test`: runs `bash tests/run.sh` on push/PR to `main`.
- `docker-smoke`: reusable/manual workflow for Docker build and smoke checks.
- `docker-release`: runs on pushed tags matching `v*.*`, then builds and pushes multi-arch images.

Release examples that match the current workflow trigger:
- `v9.5`
- `v9.5.0`

Publishing requires repository secrets:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Troubleshooting

- Missing credentials:
  - ensure `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` are present in `.env`.
- Permission issues with host volume:
  - create `./data` before first run and ensure it is writable.
- Port conflicts:
  - change `TELEGRAM_HTTP_PORT` and/or `TELEGRAM_HTTP_STAT_PORT` and map matching host ports.
- API call failures:
  - check container logs and `/data/logs/telegram-bot-api.log`.

Security note:
- `TELEGRAM_LOCAL` allows serving local files and should be enabled only in trusted environments with proper network isolation.

## Switching from api.telegram.org

To guarantee that your bot receives all updates, first deregister it from `https://api.telegram.org` by calling [logOut](https://core.telegram.org/bots/api#logout).

After logout, point your bot client to your local server address. If launched with `--local`, ensure your bot can handle absolute file paths in `getFile` responses.

## Moving Between Local Servers

If the same bot is logged in on multiple servers, update delivery is not guaranteed.

To move safely:
1. Call [logOut](https://core.telegram.org/bots/api#logout) on the old server.
2. Optionally call [deleteWebhook](https://core.telegram.org/bots/api#deletewebhook), then [close](https://core.telegram.org/bots/api#close) to reduce update loss during migration.
3. Move the bot subdirectory (named by bot user ID) from the old server's working directory to the new server's working directory.

## Documentation

- [Telegram Bots introduction](https://core.telegram.org/bots)
- [Telegram Bot API reference](https://core.telegram.org/bots/api)
- [Telegram Bot API build instructions generator](https://tdlib.github.io/telegram-bot-api/build.html)
- [@BotNews](https://t.me/botnews) and [@BotTalk](https://t.me/bottalk) for updates and discussion

## License

Telegram Bot API server source code is licensed under the Boost Software License. See [LICENSE](http://www.boost.org/LICENSE_1_0.txt) for details.
