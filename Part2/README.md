# Part 2 – Discovering a VXLAN

## Topology

```
[host1]          [host2]
  |                 |
 eth0             eth0
  |                 |
 eth1             eth1
[routeur1]      [routeur2]
  eth0 --------- eth0
  10.1.1.1/30   10.1.1.2/30
```

| Device    | Interface | Address         | Role                       |
|-----------|-----------|-----------------|----------------------------|
| routeur1  | eth0      | 10.1.1.1/30     | Underlay (VTEP)            |
| routeur1  | eth1      | –               | Slave of br0 (toward host) |
| routeur2  | eth0      | 10.1.1.2/30     | Underlay (VTEP)            |
| routeur2  | eth1      | –               | Slave of br0 (toward host) |
| host1     | eth0      | 30.1.1.1/24     | Overlay (inside VXLAN)     |
| host2     | eth0      | 30.1.1.2/24     | Overlay (inside VXLAN)     |

The VXLAN creates a virtual Layer-2 segment (VNI 10) stretched over the IP
underlay. From host1 and host2's perspective they share the same /24 LAN even
though they are physically separated. br0 on each router stitches the VXLAN
interface (vxlan10) together with the local host-facing port (eth1).

---

## Static VXLAN (unicast mode)

Each VTEP specifies the remote VTEP address explicitly.  BUM traffic
(Broadcast/Unknown-unicast/Multicast) is sent directly to the peer.

### routeur1

```sh
# Underlay
ip addr add 10.1.1.1/30 dev eth0
ip link set eth0 up

# VXLAN – VNI 10, UDP 4789, remote = routeur2's underlay IP
ip link add vxlan10 type vxlan id 10 dstport 4789 \
    local 10.1.1.1 remote 10.1.1.2 dev eth0

# Bridge
ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1    master br0
ip link set vxlan10 up && ip link set eth1 up && ip link set br0 up
```

### routeur2

```sh
ip addr add 10.1.1.2/30 dev eth0
ip link set eth0 up

ip link add vxlan10 type vxlan id 10 dstport 4789 \
    local 10.1.1.2 remote 10.1.1.1 dev eth0

ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1    master br0
ip link set vxlan10 up && ip link set eth1 up && ip link set br0 up
```

---

## Dynamic VXLAN (multicast mode)

Instead of hard-coding the remote VTEP, BUM traffic is flooded to the
multicast group **239.1.1.1**. VTEPs discover each other through IGMP
membership on the underlay link (no PIM daemon is needed when the VTEPs
are directly connected at Layer 2 on the underlay).

### routeur1 and routeur2 (same command on both)

```sh
ip link add vxlan10 type vxlan id 10 dstport 4789 \
    group 239.1.1.1 dev eth0
```

The rest of the bridge setup is identical to the static case.
`start.sh` for both routers uses this multicast form.

---

## Verifying the setup

### Ping across the VXLAN

From **host1**:
```
ping 30.1.1.2
```

### Inspect the MAC address table

On **routeur1** or **routeur2** (shows remote MACs learned via VXLAN):
```
bridge fdb show dev vxlan10
```

Example output after a first ping (routeur1 side):
```
<mac-of-host2>  dev vxlan10 dst 10.1.1.2 self
```

### Inspect live traffic on the underlay (Wireshark / tcpdump)

On **routeur1** – capture VXLAN-encapsulated packets on the underlay:
```
tcpdump -i eth0 udp port 4789 -v
```

You will see standard Ethernet frames (ARP, ICMP…) wrapped inside
UDP/VXLAN headers.  In multicast mode the first ARP request is sent to
239.1.1.1 before the unicast entry is learned.

### Check the VXLAN interface state

```
ip -d link show vxlan10
```

In multicast mode the output contains `group 239.1.1.1`.
In static mode it contains `remote 10.1.1.x`.

---

## File layout

```
Part2/
├── routeur1/
│   ├── Dockerfile   – FRR image + start.sh
│   ├── daemons      – only zebra enabled (VXLAN is kernel-managed)
│   ├── frr.conf     – minimal FRR config (hostname only)
│   └── start.sh     – underlay IP + vxlan10 + br0 setup
├── routeur2/
│   ├── Dockerfile
│   ├── daemons
│   ├── frr.conf
│   └── start.sh
├── host1/
│   ├── Dockerfile   – Alpine with iproute2/tcpdump
│   └── start.sh     – sets 30.1.1.1/24 on eth0
└── host2/
    ├── Dockerfile
    └── start.sh     – sets 30.1.1.2/24 on eth0
```
