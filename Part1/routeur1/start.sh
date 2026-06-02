#!/bin/sh
set -eu

# Start the FRR daemons requested by the subject.
/usr/lib/frr/docker-start &

# Keep the GNS3 console interactive. From here, use `vtysh` to configure FRR.
exec /bin/sh -i
