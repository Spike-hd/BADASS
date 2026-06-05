FROM alpine:latest

RUN apk add --no-cache \
    iproute2 \
    iputils \
    tcpdump \
    busybox-extras

COPY start.sh /usr/local/bin/start-host
RUN chmod +x /usr/local/bin/start-host

CMD ["/usr/local/bin/start-host"]
