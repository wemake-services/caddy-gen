# caddy-gen

[![wemake.services](https://img.shields.io/badge/style-wemake.services-green.svg?label=&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAK7OHOkAAAAbUExURQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP%2F%2F%2F5TvxDIAAAAIdFJOUwAjRA8xXANAL%2Bv0SAAAADNJREFUGNNjYCAIOJjRBdBFWMkVQeGzcHAwksJnAPPZGOGAASzPzAEHEGVsLExQwE7YswCb7AFZSF3bbAAAAABJRU5ErkJggg%3D%3D)](http://wemake.services) [![Build Status](https://travis-ci.org/wemake-services/caddy-gen.svg?branch=master)](https://travis-ci.org/wemake-services/caddy-gen) [![Dockerhub](https://img.shields.io/docker/pulls/wemakeservices/caddy-gen.svg)](https://hub.docker.com/r/wemakeservices/caddy-gen/) [![image size](https://images.microbadger.com/badges/image/wemakeservices/caddy-gen.svg)](https://microbadger.com/images/wemakeservices/caddy-gen) [![caddy's version](https://img.shields.io/badge/version-0.10.9-blue.svg)](https://github.com/mholt/caddy/tree/v0.10.10)

Perfect mix of `Caddy` and `docker-gen`.

Inspired by [`nginx-proxy`](https://github.com/jwilder/nginx-proxy).


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
      - /var/run/docker.sock:/tmp/docker.sock:ro  # needs socket to read event
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - whoami

  whoami:  # this is your service
    image: "katacoda/docker-http-server:v2"
    labels:
      - "virtual.host=myapp.com"  # your domain
      - "virtual.port=80"  # exposed port of this container
      - "virtual.tls-email=admin@myapp.com"  # ssl is now on
```

Or see [`docker-compose.yml`](https://github.com/wemake-services/caddy-gen/blob/master/docker-compose.yml) example file.


## Configuration

`caddy-gen` is configured with [`labels`](https://docs.docker.com/engine/userguide/labels-custom-metadata/).

The main idea is simple.
Every labeled service exposes a `virtual.host` to be handled.
Then, every container represents a single `upstream` to serve requests.

There are several options to configure:
- `virtual.host` is basically a domain name, see [`Caddy` docs](https://caddyserver.com/docs/proxy)
- `virtual.port` should be one of `[80, 433, 2015]`
- `virtual.tls_email` could be empty, unset or set to [valid email](https://caddyserver.com/docs/tls)

Note, that options should not differ for containers of a single service.


## See also

- Raw `Caddy` [image](https://github.com/wemake-services/caddy-docker)


## Changelog

Full changelog is available [here](https://github.com/wemake-services/caddy-gen/blob/master/CHANGELOG.md).


## License

MIT. See [LICENSE.md](https://github.com/wemake-services/caddy-gen/blob/master/LICENSE.md) for more details.
