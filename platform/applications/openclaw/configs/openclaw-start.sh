#!/bin/sh

set -eu
umask 077

# Seed the read-only Swarm config once so later UI edits persist across deployments.
mkdir -p /home/node/.openclaw
if [ ! -e /home/node/.openclaw/openclaw.json ]; then
  cp /etc/openclaw/openclaw.json /home/node/.openclaw/openclaw.json.tmp
  mv /home/node/.openclaw/openclaw.json.tmp /home/node/.openclaw/openclaw.json
fi

# Keep the image's pre-start migration checks after our bootstrap.
exec node /app/docker-entrypoint.mjs node openclaw.mjs gateway
