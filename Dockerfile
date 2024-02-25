FROM alpine:3.19.1

RUN apk update
RUN apk upgrade

RUN apk add --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git

WORKDIR telegram-bot-api

RUN rm -rf build && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && cmake --build . --target install

RUN ls -l telegram-bot-api/bin/telegram-bot-api*

CMD ["telegram-bot-api/bin/telegram-bot-api"]
