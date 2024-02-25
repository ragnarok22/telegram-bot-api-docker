FROM alpine:3.19.1

RUN apk update
RUN apk upgrade

RUN apk add --update alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git

RUN cd telegram-bot-api
RUN rm -rf build
RUN mkdir build
RUN cd build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. ..
RUN cmake --build . --target install
RUN cd ../..
RUN ls -l telegram-bot-api/bin/telegram-bot-api*

RUN cd telegram-bot-api/bin

CMD ["telegram-bot-api"]
