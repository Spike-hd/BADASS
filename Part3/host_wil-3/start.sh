#!/bin/sh

# ---------------------------------------------------------------------------
# host_wil-3 – overlay endpoint
#
# eth0 is bridged on routeur_wil-4 into br0 (together with vxlan10).
# 30.1.1.3/24 is the overlay address visible across VNI 10 to host_wil-1.
# ---------------------------------------------------------------------------

ip addr add 30.1.1.3/24 dev eth0
ip link set eth0 up

exec /bin/sh -i
