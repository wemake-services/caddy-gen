#!/bin/sh

set -o errexit
set -o nounset

# Create initial configuration:
docker-gen /code/docker-gen/templates/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command:
exec "$@"
