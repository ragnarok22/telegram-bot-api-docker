# Stage 1: Build Stage
FROM --platform=$BUILDPLATFORM alpine:3.23.3 AS build-stage

RUN apk add --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

# Shallow clone default branch with submodules
RUN git clone --depth 1 \
      --recurse-submodules --shallow-submodules \
      https://github.com/tdlib/telegram-bot-api.git /telegram-bot-api

WORKDIR /telegram-bot-api

RUN rm -rf build && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
    cmake --build . --target install


# Stage 2: Final Stage
FROM alpine:3.23.3

LABEL org.opencontainers.image.description="Telegram Bot API server provides an HTTP API for creating Telegram Bots."
LABEL org.opencontainers.image.title="telegram-bot-api"
LABEL org.opencontainers.image.url="https://github.com/ragnarok22/telegram-bot-api-docker"
LABEL org.opencontainers.image.source="https://github.com/ragnarok22/telegram-bot-api-docker"
LABEL org.opencontainers.image.version="9.4"
LABEL org.opencontainers.image.authors="Reinier Hernández<sasuke.reinier@gmail.com>"
LABEL org.opencontainers.image.licenses="BSL-1.0"

# Copy only the necessary files from the build stage
COPY --from=build-stage /telegram-bot-api/bin/ /telegram-bot-api/bin/

RUN apk add --no-cache libstdc++ libgcc && \
    rm -rf /var/cache/apk/* && \
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
