#!/bin/sh

# caddy_template is by default set to the backup to avoid adding the snippet
# multiple times to the same template, for example when a container restarts
export CADDY_TEMPLATE="${CADDY_TEMPLATE:-./docker-gen/templates/Caddyfile.bkp}"
export CADDY_SNIPPET="${CADDY_SNIPPET}"

set -o errexit
set -o nounset

# Create initial configuration:
if [[ -z "$CADDY_SNIPPET" ]]; then
  cat "$CADDY_TEMPLATE" > /code/docker-gen/templates/Caddyfile.tmpl
else
  cat "$CADDY_TEMPLATE" "$CADDY_SNIPPET" > /code/docker-gen/templates/Caddyfile.tmpl
fi
docker-gen /code/docker-gen/templates/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command:
exec "$@"
