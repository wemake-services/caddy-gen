#!/bin/sh

set -o errexit
set -o nounset

CADDY_SNIPPET="${CADDY_SNIPPET:-}"
# caddy_template is by default set to the backup to avoid adding the snippet
# multiple times to the same template, for example when a container restarts
CADDY_TEMPLATE="${CADDY_TEMPLATE:-./docker-gen/templates/Caddyfile.bkp}"

# Create template file
truncate -s 0 /code/docker-gen/templates/Caddyfile.tmpl
if [ -n "$CADDY_SNIPPET" ]; then
  cat "$CADDY_SNIPPET" >> /code/docker-gen/templates/Caddyfile.tmpl
fi
cat "$CADDY_TEMPLATE" >> /code/docker-gen/templates/Caddyfile.tmpl

# Create initial configuration:
docker-gen /code/docker-gen/templates/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command:
exec "$@"
