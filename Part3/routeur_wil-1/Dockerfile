FROM quay.io/frrouting/frr:10.4.1

COPY daemons /etc/frr/daemons
COPY frr.conf /etc/frr/frr.conf
COPY start.sh /usr/local/bin/start-router

RUN touch /etc/frr/vtysh.conf \
    && chown frr:frr /etc/frr/daemons /etc/frr/frr.conf \
    && chown frr:frrvty /etc/frr/vtysh.conf \
    && chmod 640 /etc/frr/daemons /etc/frr/frr.conf /etc/frr/vtysh.conf \
    && chmod +x /usr/local/bin/start-router

CMD ["/usr/local/bin/start-router"]
