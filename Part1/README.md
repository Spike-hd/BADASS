# Part 1 - GNS3 Docker Images

This folder contains the two Docker images required by the subject.

## Host image

`host1/Dockerfile` is based on Alpine. Alpine includes busybox by default, and
the image also installs common network tools: `ip`, `ping`, `telnet` and
`tcpdump`.

Build it with:

```sh
docker build -t hduflos-host Part1/host1
```

## Router image

`routeur1/Dockerfile` is based on FRRouting. FRR provides `zebra`, `bgpd`,
`ospfd` and `isisd`.

The enabled daemons are listed in `routeur1/daemons`:

- `zebra`: Linux routing table and interface manager.
- `bgpd`: BGP daemon.
- `ospfd`: OSPF daemon.
- `isisd`: IS-IS daemon.

`routeur1/frr.conf` intentionally does not configure any IP address, router-id,
BGP neighbor, OSPF network or IS-IS interface. The image stays generic so it can
be reused by all GNS3 routers throughout the project.

Build it with:

```sh
docker build -t hduflos-router Part1/routeur1
```

In GNS3, create one template from each image. The equipment names should include
the login, for example `hduflos-host1` and `hduflos-routeur1`.
