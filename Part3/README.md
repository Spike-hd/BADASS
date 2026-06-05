# Part 3 – BGP EVPN with VXLAN (RFC 7432)

## Overview

Part 3 extends the VXLAN overlay from Part 2 by replacing manual/multicast
MAC flooding with **BGP EVPN** as the control plane.  MAC addresses are now
distributed by the routing protocol (zero flooding for known unicast), and a
**Route Reflector** (RR) avoids the need for a full BGP mesh between VTEPs.

Key RFCs:
- **RFC 7432** – BGP MPLS-Based Ethernet VPN (adapted here without MPLS)
- **RFC 7348** – VXLAN encapsulation (VNI 10)
- **RFC 4271** – BGP-4 (iBGP within AS 65000)

---

## Topology

```
                 ┌─────────────────────────┐
                 │  hduflos-routeur_wil-1  │
                 │  Route Reflector (RR)   │
                 │  lo  = 1.1.1.1/32       │
                 │  AS  = 65000            │
                 └────┬─────────┬──────────┘
                      │eth0     │eth1    │eth2
              10.1.1.0/30  10.1.2.0/30  10.1.3.0/30
                eth0│         eth0│          eth0│
         ┌──────────┴──┐  ┌───────┴──┐  ┌───────┴──┐
         │   wil-2     │  │  wil-3   │  │  wil-4   │
         │ lo=1.1.1.2  │  │lo=1.1.1.3│  │lo=1.1.1.4│
         │ VTEP / leaf │  │   VTEP   │  │   VTEP   │
         └──────┬──────┘  └──────────┘  └────┬─────┘
               eth1                          eth1
                │                             │
         ┌──────┴──────┐               ┌──────┴──────┐
         │ host_wil-1  │               │ host_wil-3  │
         │ 30.1.1.1/24 │               │ 30.1.1.3/24 │
         └─────────────┘               └─────────────┘
```

---

## IP addressing

| Device     | Interface | Address        | Purpose                          |
|------------|-----------|----------------|----------------------------------|
| wil-1 (RR) | lo        | 1.1.1.1/32     | BGP router-id                    |
| wil-1      | eth0      | 10.1.1.1/30    | Underlay link → wil-2            |
| wil-1      | eth1      | 10.1.2.1/30    | Underlay link → wil-3            |
| wil-1      | eth2      | 10.1.3.1/30    | Underlay link → wil-4            |
| wil-2      | lo        | 1.1.1.2/32     | VTEP source IP, BGP router-id    |
| wil-2      | eth0      | 10.1.1.2/30    | Underlay link → wil-1            |
| wil-2      | eth1      | –              | Host port (slave of br0)         |
| wil-3      | lo        | 1.1.1.3/32     | VTEP source IP, BGP router-id    |
| wil-3      | eth0      | 10.1.2.2/30    | Underlay link → wil-1            |
| wil-4      | lo        | 1.1.1.4/32     | VTEP source IP, BGP router-id    |
| wil-4      | eth0      | 10.1.3.2/30    | Underlay link → wil-1            |
| wil-4      | eth1      | –              | Host port (slave of br0)         |
| host_wil-1 | eth0      | 30.1.1.1/24    | Overlay (inside VNI 10)          |
| host_wil-3 | eth0      | 30.1.1.3/24    | Overlay (inside VNI 10)          |

---

## How it works

### 1. Underlay – OSPF

All four routers run OSPF area 0.  Every loopback (1.1.1.x/32) and every
point-to-point link is redistributed so each VTEP can reach every other
VTEP's loopback over the shortest path.

```
vtysh# show ip ospf neighbor
vtysh# show ip route ospf
```

### 2. Control plane – BGP EVPN (RR)

**Dynamic neighbors** on the RR (`bgp listen range 1.1.1.0/29`): any VTEP
whose loopback falls in that /29 is automatically accepted and inherits the
`ibgp` peer-group.  VTEPs do not need to be listed individually on the RR.

VTEPs connect to the RR and advertise:
- **Type-3 (IMET)** – one route per VNI per VTEP.  Tells every peer "I am
  a VTEP for VNI 10; send BUM traffic to me."  Appears at startup even
  with no hosts running.
- **Type-2 (MAC/IP)** – one route per locally learned MAC (and optionally
  IP).  Created automatically by FRR when a frame arrives on the host port.

```
vtysh# show bgp l2vpn evpn
vtysh# show bgp l2vpn evpn route type multicast   ← type-3
vtysh# show bgp l2vpn evpn route type macip        ← type-2
```

### 3. Data plane – VXLAN (nolearning)

The VXLAN interface is created with `nolearning` so the kernel never adds
entries to the FDB from incoming encapsulated frames.  All remote MAC→VTEP
mappings are installed by FRR as **static** FDB entries when a type-2 BGP
route is received.

```sh
bridge fdb show dev vxlan10   # MAC table: remote entries have a `dst` field
```

### 4. MAC learning flow

```
host_wil-1 sends any frame
    └─ wil-2's br0 sees the source MAC on eth1
       └─ FRR zebra detects new FDB entry via netlink
          └─ bgpd generates EVPN type-2 route { MAC, VNI=10, VTEP=1.1.1.2 }
             └─ sent to RR (wil-1)
                └─ RR reflects to wil-3 and wil-4
                   └─ wil-3/wil-4 install static FDB: MAC → dst 1.1.1.2
```

---

## Verification commands

### On any VTEP (e.g. wil-4) – see all three VTEPs

```
vtysh# show bgp l2vpn evpn vni
VNI        Type RD                    Originator IP        #MACs   #ARPs
10         L2   1.1.1.4:2             1.1.1.4              0       0
```

### After starting host_wil-1 – type-2 route appears

```
vtysh# show bgp l2vpn evpn route type macip
*> [2]:[0]:[48]:[<mac-of-host_wil-1>]
   1.1.1.2         0        100     0  i
```

### Ping across the overlay

```sh
# From host_wil-1:
ping 30.1.1.3
```

The ICMP packets are VXLAN-encapsulated on the underlay (visible with
`tcpdump -i eth0 udp port 4789 -v` on any VTEP).

---

## File layout

```
Part3/
├── routeur_wil-1/          Route Reflector
│   ├── Dockerfile
│   ├── daemons             zebra + ospfd + bgpd
│   ├── frr.conf            OSPF area 0 + BGP RR with dynamic neighbors
│   └── start.sh            starts FRR only (no VXLAN on the RR)
├── routeur_wil-2/          VTEP – host_wil-1 attached on eth1
│   ├── Dockerfile
│   ├── daemons
│   ├── frr.conf            OSPF + BGP EVPN client (advertise-all-vni)
│   └── start.sh            loopback IP → FRR → vxlan10 + br0
├── routeur_wil-3/          VTEP – no host (shows up in VTEP table)
│   ├── Dockerfile
│   ├── daemons
│   ├── frr.conf
│   └── start.sh
├── routeur_wil-4/          VTEP – host_wil-3 attached on eth1
│   ├── Dockerfile
│   ├── daemons
│   ├── frr.conf
│   └── start.sh
├── host_wil-1/             Overlay endpoint (30.1.1.1/24)
│   ├── Dockerfile
│   └── start.sh
└── host_wil-3/             Overlay endpoint (30.1.1.3/24)
    ├── Dockerfile
    └── start.sh
```
