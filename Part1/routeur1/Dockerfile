FROM quay.io/frrouting/frr:latest

# The FRR image already provides the routing stack and a busybox-compatible
# base system. We only copy the daemon list and the shared FRR configuration.
COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf

RUN chown frr:frr /etc/frr/daemons /etc/frr/frr.conf \
    && chmod 640 /etc/frr/daemons /etc/frr/frr.conf

# Start FRR normally so zebra, bgpd, ospfd and isisd are actually launched.
CMD ["/usr/lib/frr/docker-start"]
