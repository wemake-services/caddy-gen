# caddy-gen

[![wemake.services](https://img.shields.io/badge/-wemake.services-green.svg?label=%20&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAK7OHOkAAAAbUExURQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP%2F%2F%2F5TvxDIAAAAIdFJOUwAjRA8xXANAL%2Bv0SAAAADNJREFUGNNjYCAIOJjRBdBFWMkVQeGzcHAwksJnAPPZGOGAASzPzAEHEGVsLExQwE7YswCb7AFZSF3bbAAAAABJRU5ErkJggg%3D%3D)](https://wemake.services) [![Build Status](https://travis-ci.org/wemake-services/caddy-gen.svg?branch=master)](https://travis-ci.org/wemake-services/caddy-gen) [![Dockerhub](https://img.shields.io/docker/pulls/wemakeservices/caddy-gen.svg)](https://hub.docker.com/r/wemakeservices/caddy-gen/) [![image size](https://images.microbadger.com/badges/image/wemakeservices/caddy-gen.svg)](https://microbadger.com/images/wemakeservices/caddy-gen) [![caddy's version](https://img.shields.io/badge/version-0.10.11-blue.svg)](https://github.com/mholt/caddy/tree/v0.10.11)

A perfect mix of [`Caddy`](https://github.com/mholt/caddy), [`docker-gen`](https://github.com/jwilder/docker-gen), and [`forego`](https://github.com/jwilder/forego). Inspired by [`nginx-proxy`](https://github.com/jwilder/nginx-proxy).

---


## Why

Using `Caddy` as your primary web server is super simple.
But when you need to scale your application Caddy is limited to its static configuration.

To overcome this issue we are using `docker-gen` to generate configuration everytime a container spawns or dies.
Now scaling is easy!


## Usage

This image is created to be used in a single container.

```yaml
version: "3"
services:
  caddy-gen:
    container_name: caddy-gen
    image: "wemakeservices/caddy-gen:latest"
    restart: always
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro  # needs socket to read events
      - ./certs/acme:/etc/caddy/acme  # to save acme
      - ./certs/ocsp:/etc/caddy/ocsp  # to save certificates
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - whoami

  whoami:  # this is your service
    image: "katacoda/docker-http-server:v2"
    labels:
      - "virtual.host=myapp.com example.com"  # your domains separated with a space
      - "virtual.alias=www.myapp.com"  # alias for your domain (optional)
      - "virtual.port=80"  # exposed port of this container
      - "virtual.tls-email=admin@myapp.com"  # ssl is now on
      - "virtual.websockets" # enable websocket passthrough
```

Or see [`docker-compose.yml`](https://github.com/wemake-services/caddy-gen/blob/master/docker-compose.yml) example file.


## Configuration

`caddy-gen` is configured with [`labels`](https://docs.docker.com/engine/userguide/labels-custom-metadata/).

The main idea is simple.
Every labeled service exposes a `virtual.host` to be handled.
Then, every container represents a single `upstream` to serve requests.

There are several options to configure:
- `virtual.host` is basically a domain name, see [`Caddy` docs](https://caddyserver.com/docs/proxy)
- `virtual.alias` (optional) domain alias, useful for `www` prefix with redirect. For example `www.myapp.com`. Alias will always redirect to the host above.
- `virtual.port` exposed port of the container
- `virtual.tls_email` could be empty, unset or set to [valid email](https://caddyserver.com/docs/tls)
- `virtual.websocket` when set, enables websocket connection passthrough

Note, that options should not differ for containers of a single service.

### Backing up certificates

Certificates are stored in `/etc/caddy/acme/` and `/etc/caddy/ocsp` folders.
Make them `volume`s to save them on your host machine.

### Versions

This image supports three [build-time](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg) arguments:

- `CADDY_VERSION` to change the current version of [`Caddy`](https://github.com/mholt/caddy/releases)
- `FOREGO_VERSION` to change the current version of [`forego`](https://github.com/jwilder/forego/releases)
- `DOCKER_GEN_VERSION` to change the current version of [`docker-gen`](https://github.com/jwilder/docker-gen/releases)


## See also

- Raw `Caddy` [image](https://github.com/wemake-services/caddy-docker)


## Changelog

Full changelog is available [here](https://github.com/wemake-services/caddy-gen/blob/master/CHANGELOG.md).


## License

MIT. See [LICENSE.md](https://github.com/wemake-services/caddy-gen/blob/master/LICENSE.md) for more details.
