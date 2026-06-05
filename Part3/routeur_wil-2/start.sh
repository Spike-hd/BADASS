#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# routeur_wil-2 – VTEP leaf startup
#
# Sequence:
#   1. Set loopback IP immediately (needed as VXLAN local address and BGP
#      update-source before FRR fully initialises).
#   2. Start FRR – zebra configures underlay eth0 from frr.conf; ospfd
#      and bgpd start the EVPN control plane.
#   3. Create vxlan10 + br0 – kernel VXLAN interface and bridge.
#      FRR (zebra) detects the new netlink events and begins managing them.
#
# Interface roles:
#   lo      1.1.1.2/32  VTEP source IP, BGP router-id
#   eth0    underlay    managed by zebra (IP in frr.conf)
#   eth1    host port   enslaved to br0, no IP
#   vxlan10 VXLAN VNI10 enslaved to br0
#   br0     bridge      L2 domain shared between eth1 and vxlan10
# ---------------------------------------------------------------------------

# Step 1 – loopback IP must exist before "ip link add vxlan10 ... local"
ip addr add 1.1.1.2/32 dev lo 2>/dev/null || true

# Step 2 – start FRR daemons
/usr/lib/frr/docker-start &
sleep 3   # allow zebra to configure eth0 from frr.conf before bridge setup

# Step 3 – VXLAN interface
# VNI 10, UDP port 4789 (IANA standard), source IP = loopback.
# nolearning: disables kernel data-plane MAC learning on the VXLAN port.
#             FRR bgpd handles MAC distribution via EVPN type-2 routes
#             and installs them as static FDB entries – this is the whole
#             point of BGP EVPN (control-plane MAC learning).
ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.2 nolearning

# Step 4 – bridge br0
# Stitches vxlan10 (tunnel side) and eth1 (host side) into one L2 domain.
# No IP is assigned to br0 itself – it is a pure Layer-2 switch.
ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1    master br0

ip link set vxlan10 up
ip link set eth1    up
ip link set br0     up

exec /bin/sh -i
