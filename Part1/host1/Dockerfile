FROM alpine:latest

RUN apk add --no-cache \
    iproute2 \
    iputils \
    tcpdump \
    busybox-extras

CMD ["tail", "-f", "/dev/null"]
