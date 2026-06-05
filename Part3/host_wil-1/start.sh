#!/bin/sh

# ---------------------------------------------------------------------------
# host_wil-1 – overlay endpoint
#
# eth0 is bridged on routeur_wil-2 into br0 (together with vxlan10).
# 30.1.1.1/24 is the overlay address visible across VNI 10 to host_wil-3.
#
# Note: the VTEP (routeur_wil-2) learns this host's MAC address as soon as
# any frame is sent on eth0 (e.g. an ARP probe at startup).  FRR then
# automatically advertises that MAC as an EVPN type-2 route to the RR,
# which reflects it to routeur_wil-3 and routeur_wil-4.
# No IP assignment is required for type-2 MAC learning to happen.
# ---------------------------------------------------------------------------

ip addr add 30.1.1.1/24 dev eth0
ip link set eth0 up

exec /bin/sh -i
