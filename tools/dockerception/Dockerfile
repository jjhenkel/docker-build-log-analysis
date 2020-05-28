FROM docker:dind

RUN apk add --no-cache coreutils git curl openssh

RUN apk add -u --no-cache --virtual .build-deps \
      git gcc libc-dev make autoconf automake libtool gawk flex file diffutils \
    && mkdir -p /usr/src && cd /usr/src \
    && git clone --depth 1 --branch v5.0.0 https://github.com/johnkerl/miller.git \
    && cd /usr/src/miller \
    && autoreconf -fiv && ./configure --prefix=/usr/local \
    && cd /usr/src/miller \
    && sed -i 's/ -pg / /' c/Makefile.in \
    && make && make install \
    && rm -rf /usr/src \
    && apk del .build-deps

RUN apk add --no-cache jq findutils bash python3

COPY . /app

ENTRYPOINT [ "/app/entrypoint.sh" ]
