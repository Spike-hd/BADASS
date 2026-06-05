#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# routeur_wil-4 – VTEP leaf startup (connected to host_wil-3)
#
# Mirror of routeur_wil-2 with its own loopback (1.1.1.4) and underlay IP.
# eth1 is the host-facing port bridged into the VNI-10 overlay.
# ---------------------------------------------------------------------------

ip addr add 1.1.1.4/32 dev lo 2>/dev/null || true

/usr/lib/frr/docker-start &
sleep 3

ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.4 nolearning

ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1    master br0

ip link set vxlan10 up
ip link set eth1    up
ip link set br0     up

exec /bin/sh -i
