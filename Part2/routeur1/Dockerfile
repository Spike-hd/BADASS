FROM quay.io/frrouting/frr:10.4.1

# The FRR image already provides the routing stack and a busybox-compatible
# base system. We only copy the daemon list and the shared FRR configuration.
COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY start.sh /usr/local/bin/start-router

RUN touch /etc/frr/vtysh.conf \
    && chown frr:frr /etc/frr/daemons /etc/frr/frr.conf \
    && chown frr:frrvty /etc/frr/vtysh.conf \
    && chmod 640 /etc/frr/daemons /etc/frr/frr.conf /etc/frr/vtysh.conf \
    && chmod +x /usr/local/bin/start-router

# Start FRR, then keep an interactive shell for the GNS3 console.
CMD ["/usr/local/bin/start-router"]
