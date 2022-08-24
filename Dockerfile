FROM shadowsocks/shadowsocks-libev

USER root

RUN cd /tmp && wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip \
    && mkdir badvpn-master/build && cd badvpn-master/build \
    && apk add --no-cache --virtual .build-deps build-base cmake linux-headers \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 \
    && make install \
    && apk del .build-deps \
    && rm -rf /tmp/master.zip /tmp/badvpn-master

RUN apk add jq

COPY run.sh /bin/run.sh

CMD ["/bin/sh", "/bin/run.sh"]
