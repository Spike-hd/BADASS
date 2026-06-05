#!/bin/sh

# ---------------------------------------------------------------------------
# host2 – overlay IP configuration
#
# eth0 is bridged on routeur2 into br0 (together with vxlan10).
# The address 30.1.1.2/24 is in the overlay network visible across the VXLAN.
# ---------------------------------------------------------------------------

ip addr add 30.1.1.2/24 dev eth0
ip link set eth0 up

exec /bin/sh -i
