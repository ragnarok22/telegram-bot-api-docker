# Stage 1: Build Stage
FROM alpine:3.24.1 AS build-stage

ARG TELEGRAM_BOT_API_COMMIT=adfd7f6a8e990272851777eeb3ae0def4216f161

RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

# Fetch the pinned upstream revision and its submodules.
RUN git init /telegram-bot-api && \
    cd /telegram-bot-api && \
    git remote add origin https://github.com/tdlib/telegram-bot-api.git && \
    git fetch --depth 1 origin "$TELEGRAM_BOT_API_COMMIT" && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive --depth 1

WORKDIR /telegram-bot-api

RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
    cmake --build . --target install


# Stage 2: Final Stage
FROM alpine:3.24.1

LABEL org.opencontainers.image.description="Telegram Bot API server provides an HTTP API for creating Telegram Bots."
LABEL org.opencontainers.image.title="telegram-bot-api"
LABEL org.opencontainers.image.url="https://github.com/ragnarok22/telegram-bot-api-docker"
LABEL org.opencontainers.image.source="https://github.com/ragnarok22/telegram-bot-api-docker"
LABEL org.opencontainers.image.version="10.2.0"
LABEL org.opencontainers.image.authors="Reinier Hernández<sasuke.reinier@gmail.com>"
LABEL org.opencontainers.image.licenses="BSL-1.0"

# Copy only the necessary files from the build stage
COPY --from=build-stage /telegram-bot-api/bin/ /telegram-bot-api/bin/

RUN apk add --no-cache libstdc++ libgcc && \
    addgroup -S botapi && adduser -S -G botapi botapi && \
    chown -R botapi:botapi /telegram-bot-api/bin && \
    mkdir -p /data/logs /tmp && \
    chown -R botapi:botapi /data /tmp

WORKDIR /telegram-bot-api/bin

# COPY entrypoint.sh /telegram-bot-api/bin/entrypoint.sh
COPY --chmod=755 entrypoint.sh /telegram-bot-api/bin/entrypoint.sh

VOLUME /data/logs

EXPOSE 8081 8082

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:8081/ || exit 1

USER botapi

ENTRYPOINT ["./entrypoint.sh"]
