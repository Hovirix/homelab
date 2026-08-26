#!/bin/sh

set -eu
umask 077

api_key="$(cat /run/secrets/netdata_streaming_api_key)"

case "${NETDATA_STREAM_ROLE}" in
  parent)
    cat > /etc/netdata/stream.conf <<EOF
[${api_key}]
type = api
enabled = yes
allow from = 10.*
db = dbengine
health enabled = yes
enable replication = yes
replication period = 20m
EOF
    ;;
  child)
    cat > /etc/netdata/stream.conf <<EOF
[stream]
enabled = yes
destination = ${NETDATA_STREAM_DESTINATION}
api key = ${api_key}
EOF
    ;;
  *)
    printf '%s\n' "NETDATA_STREAM_ROLE must be parent or child" >&2
    exit 1
    ;;
esac

exec /usr/sbin/run.sh "$@"
