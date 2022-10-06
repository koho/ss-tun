FROM ghcr.io/shadowsocks/sslocal-rust:latest

RUN cd /tmp && apk add --no-cache --virtual .build-deps git gcc autoconf make libtool automake zlib-dev openssl asciidoc xmlto libpcre32 libev-dev g++ linux-headers \
    && git clone https://github.com/shadowsocks/simple-obfs.git \
    && cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure && make \
    && make install \
    && cd /tmp \
    && apk del .build-deps \
    && rm -rf /tmp/simple-obfs

RUN apk add jq libev

COPY run.sh /bin/run.sh

CMD ["/bin/sh", "/bin/run.sh"]
