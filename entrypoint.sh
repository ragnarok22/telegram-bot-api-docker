#!/bin/sh
set -e

if [ -n "${1}" ]; then
  exec "$@"
fi

ARGS=""

# HTTP listening port (default is 8081)
if [ -n "$TELEGRAM_HTTP_PORT" ]; then
  ARGS=" --http-port $TELEGRAM_API_PORT"
else
  ARGS=" --http-port 8081"
fi

# HTTP statistics port (default is 8082)
if [ -n "$TELEGRAM_HTTP_STAT_PORT" ]; then
  ARGS="$ARGS --http-stat-port $TELEGRAM_HTTP_STAT_PORT"
else
  ARGS="$ARGS --http-stat-port 8082"
fi

# server working directory
if [ -n "$TELEGRAM_DIR" ]; then
  ARGS="$ARGS --dir $TELEGRAM_DIR"
else
  ARGS="$ARGS --dir /data"
fi

# directory for storing HTTP server temporary files
if [ -n "$TELEGRAM_TEMP_DIR" ]; then
  ARGS="$ARGS --temp-dir $TELEGRAM_TEMP_DIR"
else
  ARGS="$ARGS --temp-dir /tmp"
fi

# path to the file where the log will be written
if [ -n "$TELEGRAM_LOG_FILE" ]; then
  ARGS="$ARGS --log $TELEGRAM_LOG_FILE"
else
  ARGS="$ARGS --log /data/logs/telegram-bot-api.log"
fi

# allow the Bot API server to serve local requests
if [ -n "$TELEGRAM_LOCAL" ]; then
  ARGS="$ARGS --local"
fi

VERSION=$(./telegram-bot-api --version)

echo "Starting telegram-bot-api ($VERSION) with args: $ARGS"

./telegram-bot-api $ARGS
