#!/usr/bin/env bash
set -exuo pipefail

# test a docker process
docker ps | grep -q caddy-gen

# test availability and status code
curl 127.0.0.1:80

# test image size < 100MB
(( $(docker inspect caddy-gen:latest -f '{{.Size}}') < 100 * 2**20 ))

# test feature CADDY_TEMPLATE
printf 'http://test-template.localhost {\n  respond "template"\n}\n' > /tmp/template.tmpl
docker cp /tmp/template.tmpl caddy-gen:/tmp/template.tmpl
docker exec caddy-gen sh -c 'export CADDY_TEMPLATE=/tmp/template.tmpl && sh /code/docker-entrypoint.sh'
sleep 2
test "$(curl 0.0.0.0:80 -s -H 'Host: test-template.localhost')" = 'template'

# test feature CADDY_SNIPPET
printf 'http://test-snippet.localhost {\n  respond "snippet"\n}\n' > /tmp/snippet.tmpl
docker cp /tmp/snippet.tmpl caddy-gen:/tmp/snippet.tmpl
docker exec caddy-gen sh \
  -c 'export CADDY_TEMPLATE=/tmp/template.tmpl CADDY_SNIPPET=/tmp/snippet.tmpl && sh /code/docker-entrypoint.sh'
sleep 2
test "$(curl 0.0.0.0:80 -s -H 'Host: test-template.localhost')" = 'template'
test "$(curl 0.0.0.0:80 -s -H 'Host: test-snippet.localhost')" = 'snippet'
