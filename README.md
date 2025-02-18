# Telegram Bot API Dockerized
![Dockerized Telegram Bot API](https://github.com/ragnarok22/telegram-bot-api-docker/assets/8838803/546002cc-ab83-494e-8c57-c1e5d18246c9)

![Docker Image Version](https://img.shields.io/docker/v/ragnarok22/telegram-bot-api-docker)
![Docker Pulls](https://img.shields.io/docker/pulls/ragnarok22/telegram-bot-api-docker)
![Docker Image Size](https://img.shields.io/docker/image-size/ragnarok22/telegram-bot-api-docker)

Dockerized [Telegram Bot API](https://github.com/tdlib/telegram-bot-api) server.

The [Telegram Bot API](https://github.com/tdlib/telegram-bot-api) provides an HTTP API for creating [Telegram Bots](https://core.telegram.org/bots).

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [Moving a bot to a local server](#switching)
- [Moving a bot from one local server to another](#moving)
- [License](#license)

## Installation

- Install [Docker](https://docs.docker.com/get-docker/)
- Pull the image from Docker Hub
  ```bash
  docker pull ragnarok22/telegram-bot-api-docker
  ```
- Create a .env file with the following content
  ```bash
  TELEGRAM_API_ID=12345
  TELEGRAM_API_HASH=1234567890abcdef1234567890abcdef
  ```
  You can get the `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` from [Telegram's website](https://my.telegram.org)
- Run the container
  ```bash
  docker run -d -p 8081:8081 ragnarok22/telegram-bot-api-docker
  ```
- The server will be available at `http://localhost:8081`

Also, you can use Docker Compose to run the container
```yaml
services:
  telegram-bot-api:
    image: ragnarok22/telegram-bot-api-docker
    ports:
      - "8081:8081"
    env_file:
      - .env
```

## Environment Variables

- `TELEGRAM_API_ID`: The API ID obtained from [Telegram's website](https://my.telegram.org)
- `TELEGRAM_API_HASH`: The API hash obtained from [Telegram's website](https://my.telegram.org)
- `TELEGRAM_HTTP_PORT`: The port the server will listen to. Default is `8081`
- `TELEGRAM_HTTP_STAT_PORT`: The port the server will listen to for statistics. Default is `8082`
- `TELEGRAM_DIR`: The directory where the server will store the data. Default is `/data`
- `TELEGRAM_TEMP_DIR`: The directory where the server will store temporary files. Default is `/tmp`
- `TELEGRAM_LOG_FILE`: The file where the server will store the logs. Default is `/data/logs/telegram-bot-api.log`
- `TELEGRAM_LOCAL`: If set to `true`, the server will run in local mode. Default is `false`

## Usage

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
