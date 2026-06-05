#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# routeur_wil-1 – Route Reflector startup
#
# This device only runs the control plane (OSPF + BGP EVPN).
# It has no VXLAN interface and never forwards overlay traffic.
# All interface IPs and routing configuration are in frr.conf.
# ---------------------------------------------------------------------------

# Start all enabled FRR daemons (zebra, ospfd, bgpd).
# They read /etc/frr/frr.conf on startup.
/usr/lib/frr/docker-start &

# Keep the GNS3 console interactive (use `vtysh` to inspect state).
exec /bin/sh -i
