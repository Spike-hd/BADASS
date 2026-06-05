#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# routeur_wil-3 – VTEP leaf startup (no local host in this topology)
#
# This VTEP participates fully in the EVPN control plane and VNI 10.
# It advertises a type-3 (IMET) route so other VTEPs know to include it
# in the BUM ingress-replication list.  It can receive traffic for any MAC
# learned via BGP.  A host can be attached to eth1 at any time.
# ---------------------------------------------------------------------------

ip addr add 1.1.1.3/32 dev lo 2>/dev/null || true

/usr/lib/frr/docker-start &
sleep 3

# VXLAN + bridge (no host interface added here – eth1 can be added later)
ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.3 nolearning

ip link add br0 type bridge
ip link set vxlan10 master br0

ip link set vxlan10 up
ip link set br0     up

exec /bin/sh -i
