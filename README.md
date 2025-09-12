# Telegram Bot API Dockerized
![Dockerized Telegram Bot API](https://github.com/ragnarok22/telegram-bot-api-docker/assets/8838803/546002cc-ab83-494e-8c57-c1e5d18246c9)

![Docker Image Version](https://img.shields.io/docker/v/ragnarok22/telegram-bot-api-docker)
![Docker Pulls](https://img.shields.io/docker/pulls/ragnarok22/telegram-bot-api-docker)
![Docker Image Size](https://img.shields.io/docker/image-size/ragnarok22/telegram-bot-api-docker)
[![test](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/test.yml/badge.svg)](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/test.yml)
[![docker-smoke](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/docker-smoke.yml/badge.svg)](https://github.com/ragnarok22/telegram-bot-api-docker/actions/workflows/docker-smoke.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ragnarok22/telegram-bot-api-docker)

Dockerized [Telegram Bot API](https://github.com/tdlib/telegram-bot-api) server.

The [Telegram Bot API](https://github.com/tdlib/telegram-bot-api) provides an HTTP API for creating [Telegram Bots](https://core.telegram.org/bots).

## Table of Contents
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [Usage](#usage)
- [Docker Compose](#docker-compose)
- [Apple Silicon / ARM64](#apple-silicon-m1m2m3-and-arm64)
- [Development](#development)
- [Documentation](#documentation)
- [Switching](#switching)
- [Moving](#moving)
- [License](#license)

## Quick Start

- Install [Docker](https://docs.docker.com/get-docker/)
- Pull the image (multi-arch):
  ```bash
  docker pull ragnarok22/telegram-bot-api-docker
  ```
- Create a `.env` file:
  ```bash
  TELEGRAM_API_ID=12345
  TELEGRAM_API_HASH=1234567890abcdef1234567890abcdef
  # Optional overrides
  # TELEGRAM_HTTP_PORT=8081
  # TELEGRAM_HTTP_STAT_PORT=8082
  # TELEGRAM_DIR=/data
  # TELEGRAM_TEMP_DIR=/tmp
  # TELEGRAM_LOG_FILE=/data/logs/telegram-bot-api.log
  # TELEGRAM_LOCAL=true
  ```
  Get `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` from https://my.telegram.org
- Run the container (API on 8081, stats on 8082):
  ```bash
  docker run -d --name telegram-bot-api \
    --env-file .env \
    -p 8081:8081 -p 8082:8082 \
    -v "$(pwd)/data:/data" \
    -v "$(pwd)/logs:/data/logs" \
    ragnarok22/telegram-bot-api-docker
  ```
- Verify the API (replace <token>):
  ```bash
  curl http://localhost:8081/bot<TOKEN>/getMe
  ```
  Logs are written to `/data/logs/telegram-bot-api.log` inside the container.

## Docker Compose

Minimal compose service:
```yaml
services:
  telegram-bot-api:
    image: ragnarok22/telegram-bot-api-docker
    env_file: .env
    ports:
      - "8081:8081"
      - "8082:8082" # optional: statistics
    volumes:
      - ./data:/data
      - ./logs:/data/logs
```

Bring it up:
```bash
docker compose up -d
```

The compose configuration persists bot data in `./data` and logs in `./logs`.

## Apple Silicon (M1/M2/M3) and ARM64

The image supports multi-platform builds for both `linux/amd64` and `linux/arm64`. 

**For pre-built images:** Docker will automatically pull the correct variant for your host architecture.

**For local builds on ARM64 (Apple Silicon):** The Dockerfile now supports native ARM64 builds. Simply run:
```bash
docker build -t telegram-bot-api .
```

**Running on Apple Silicon:** If you still see platform warnings, force the platform explicitly:
```bash
docker run -d --platform linux/arm64/v8 --env-file .env -p 8081:8081 ragnarok22/telegram-bot-api-docker
```

### Building from Source

To build the image locally:
```bash
docker build -t telegram-bot-api:dev .
```

The Dockerfile automatically creates the necessary log directories and handles platform-specific builds.

## Environment Variables

- `TELEGRAM_API_ID` (required): API ID from https://my.telegram.org
- `TELEGRAM_API_HASH` (required): API hash from https://my.telegram.org
- `TELEGRAM_HTTP_PORT` (optional): HTTP API port. Default `8081`.
- `TELEGRAM_HTTP_STAT_PORT` (optional): Statistics port. Default `8082`.
- `TELEGRAM_DIR` (optional): Data directory. Default `/data`.
- `TELEGRAM_TEMP_DIR` (optional): Temp directory. Default `/tmp`.
- `TELEGRAM_LOG_FILE` (optional): Log file path. Default `/data/logs/telegram-bot-api.log`.
- `TELEGRAM_LOCAL` (optional): `1` or `true` to enable `--local` mode, allowing the server to serve local files. Default `false`.
- `TELEGRAM_EXTRA_ARGS` (optional): Additional flags passed verbatim to `telegram-bot-api` (e.g., `--max-webhook-connections 80`).

## Usage

- Run with `.env` and expose API and stats:
  ```bash
  docker run -d --env-file .env -p 8081:8081 -p 8082:8082 ragnarok22/telegram-bot-api-docker
  ```
- Pass additional flags by setting env vars above. For options not covered by env vars, use `TELEGRAM_EXTRA_ARGS`.
- To bypass the entrypoint and run a custom command (e.g., get version), use:
  ```bash
  docker run --rm ragnarok22/telegram-bot-api-docker ./telegram-bot-api --version
  ```
- Replace `<TOKEN>` and test:
  ```bash
  curl http://localhost:8081/bot<TOKEN>/getMe
  ```

Notes
- `/data` stores bot data; mount it to persist sessions across restarts.
- Logs go to `/data/logs/telegram-bot-api.log`.
- Statistics are exposed on `TELEGRAM_HTTP_STAT_PORT` (default 8082).

Security note
- Enabling `TELEGRAM_LOCAL` allows serving local files; use only in trusted environments and ensure proper network isolation.

Troubleshooting
- If using host volumes, ensure the container user can write: create the folders before starting or adjust ownership/permissions on `./data` and `./logs` on the host.
- If ports are in use, change `TELEGRAM_HTTP_PORT`/`TELEGRAM_HTTP_STAT_PORT` and publish the new ports.
- If API calls fail, verify `TELEGRAM_API_ID`/`TELEGRAM_API_HASH` and check the log file.

## Development

- Build image (local): `docker build -t telegram-bot-api:dev .`
- Run locally: `docker run -d --env-file .env -p 8081:8081 telegram-bot-api:dev`
- Compose: `docker compose up -d`
- Entry script tests: `bash tests/run.sh`

## Documentation

See [Bots: An introduction for developers](https://core.telegram.org/bots) for a brief description of Telegram Bots and their features.

See the [Telegram Bot API documentation](https://core.telegram.org/bots/api) for a description of the Bot API interface and a complete list of available classes, methods and updates.

See the [Telegram Bot API server build instructions generator](https://tdlib.github.io/telegram-bot-api/build.html) for detailed instructions on how to build the Telegram Bot API server.

Subscribe to [@BotNews](https://t.me/botnews) to be the first to know about the latest updates and join the discussion in [@BotTalk](https://t.me/bottalk).

## Switching

To guarantee that your bot will receive all updates, you must deregister it with the `https://api.telegram.org` server by calling the method [logOut](https://core.telegram.org/bots/api#logout).
After the bot is logged out, you can replace the address to which the bot sends requests with the address of your local server and use it in the usual way.
If the server is launched in `--local` mode, make sure that the bot can correctly handle absolute file paths in response to `getFile` requests.

## Moving

If the bot is logged in on more than one server simultaneously, there is no guarantee that it will receive all updates.
To move a bot from one local server to another you can use the method [logOut](https://core.telegram.org/bots/api#logout) to log out on the old server before switching to the new one.

If you want to avoid losing updates between logging out on the old server and launching on the new server, you can remove the bot's webhook using the method
[deleteWebhook](https://core.telegram.org/bots/api#deletewebhook), then use the method [close](https://core.telegram.org/bots/api#close) to close the bot instance.
After the instance is closed, locate the bot's subdirectory in the working directory of the old server by the bot's user ID, move the subdirectory to the working directory of the new server
and continue sending requests to the new server as usual.

## License

Telegram Bot API server source code is licensed under the terms of the Boost Software License. See [LICENSE](http://www.boost.org/LICENSE_1_0.txt) for more information.
