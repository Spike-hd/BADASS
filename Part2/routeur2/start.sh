#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# routeur2 – VXLAN setup
#
# Topology:
#   [host1] --eth1-- [routeur1] --eth0-- [routeur2] --eth1-- [host2]
#
# Underlay: 10.1.1.0/30  (routeur1=.1, routeur2=.2)
# Overlay : 30.1.1.0/24  (host1=.1, host2=.2 configured on the hosts)
# VXLAN   : VNI 10, bridge br0, UDP port 4789
# ---------------------------------------------------------------------------

# Start the FRR daemons (only zebra is enabled in the daemons file).
/usr/lib/frr/docker-start &

# Give the kernel and FRR a moment to initialise before touching interfaces.
sleep 2

# ---------------------------------------------------------------------------
# UNDERLAY – eth0 links the two routers directly.
# ---------------------------------------------------------------------------
ip addr add 10.1.1.2/30 dev eth0
ip link set eth0 up

# ---------------------------------------------------------------------------
# VXLAN INTERFACE – two equivalent modes; choose one:
#
# (A) STATIC / UNICAST – the remote VTEP address is hard-coded.
#     Simpler but does not scale; every VTEP must know every other VTEP.
#
#   ip link add vxlan10 type vxlan id 10 dstport 4789 \
#       local 10.1.1.2 remote 10.1.1.1 dev eth0
#
# (B) DYNAMIC / MULTICAST – BUM traffic (Broadcast, Unknown-unicast,
#     Multicast) is flooded to the multicast group 239.1.1.1.
#     VTEPs discover each other via IGMP join on the underlay.
# ---------------------------------------------------------------------------
ip link add vxlan10 type vxlan id 10 dstport 4789 \
    group 239.1.1.1 dev eth0

# ---------------------------------------------------------------------------
# BRIDGE – br0 stitches vxlan10 (the tunnel) and eth1 (the host side)
# into one Layer-2 domain.  No IP is assigned to br0 itself.
# ---------------------------------------------------------------------------
ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1  master br0

ip link set vxlan10 up
ip link set eth1    up
ip link set br0     up

# Keep the GNS3 console interactive.
exec /bin/sh -i
