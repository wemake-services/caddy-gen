#!/bin/sh

set -o errexit
set -o nounset

# Create initial configuration:
cat $CADDY_SNIPPET >> /code/docker-gen/templates/Caddyfile.tmpl
docker-gen /code/docker-gen/templates/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command:
exec "$@"
