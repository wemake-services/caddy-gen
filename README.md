# caddy-gen

[![wemake.services](https://img.shields.io/badge/-wemake.services-green.svg?label=%20&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAALGPC%2FxhBQAAAAFzUkdCAK7OHOkAAAAbUExURQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP%2F%2F%2F5TvxDIAAAAIdFJOUwAjRA8xXANAL%2Bv0SAAAADNJREFUGNNjYCAIOJjRBdBFWMkVQeGzcHAwksJnAPPZGOGAASzPzAEHEGVsLExQwE7YswCb7AFZSF3bbAAAAABJRU5ErkJggg%3D%3D)](https://wemake.services)
[![Build Status](https://travis-ci.com/wemake-services/caddy-gen.svg?branch=master)](https://travis-ci.com/wemake-services/caddy-gen)
[![Dockerhub](https://img.shields.io/docker/pulls/wemakeservices/caddy-gen.svg)](https://hub.docker.com/r/wemakeservices/caddy-gen/)
[![image size](https://images.microbadger.com/badges/image/wemakeservices/caddy-gen.svg)](https://microbadger.com/images/wemakeservices/caddy-gen)
[![caddy's version](https://img.shields.io/badge/version-0.10.12-blue.svg)](https://github.com/mholt/caddy/tree/v0.10.12)

A perfect mix of [`Caddy`](https://github.com/mholt/caddy), [`docker-gen`](https://github.com/jwilder/docker-gen), and [`forego`](https://github.com/jwilder/forego). Inspired by [`nginx-proxy`](https://github.com/jwilder/nginx-proxy).

---

## Why

Using `Caddy` as your primary web server is super simple.
But when you need to scale your application Caddy is limited to its static configuration.

To overcome this issue we are using `docker-gen` to generate configuration everytime a container spawns or dies.
Now scaling is easy!

## CADDY 2

BREAKING CHANGES since [version 0.3.0](https://github.com/wemake-services/caddy-gen/releases/tag/0.3.0)!

Options to configure:

- `virtual.host` domain name, don't pass `http://` or `https://`, you can separate them with space,
- `virtual.alias` domain alias, e.q. `www` prefix,
- `virtual.port` port exposed by container, e.g. `3000` for React apps in development,
- `virtual.tls-email` the email address to use for the ACME account managing the site's certificates,
- `virtual.auth.path` with
- `virtual.auth.username` and
- `virtual.auth.password` together provide HTTP basic authentication.

Password should be a string `base64` encoded from `bcrypt` hash. You can use https://bcrypt-generator.com/ with default config and https://www.base64encode.org/.

## Backing up certificates

To backup certificates make a volume:

```yaml
services:
  caddy:
    volumes:
      - ./caddy-info:/data/caddy
```

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
      - /var/run/docker.sock:/tmp/docker.sock:ro # needs socket to read events
      - ./caddy-info:/data/caddy # needs volume to back up certificates
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - whoami

  whoami: # this is your service
    image: "katacoda/docker-http-server:v2"
    labels:
      - "virtual.host=myapp.com" # your domain
      - "virtual.alias=www.myapp.com" # alias for your domain (optional)
      - "virtual.port=80" # exposed port of this container
      - "virtual.tls-email=admin@myapp.com" # ssl is now on
      - "virtual.auth.path=/secret/*" # path basic authnetication applys to
      - "virtual.auth.username=admin" # Optionally add http basic authentication
      - "virtual.auth.password=JDJ5JDEyJEJCdzJYM0pZaWtMUTR4UVBjTnRoUmVJeXQuOC84QTdMNi9ONnNlbDVRcHltbjV3ME1pd2pLCg==" # By specifying both username and password hash
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
- `virtual.tls-email` could be empty, unset or set to [valid email](https://caddyserver.com/docs/caddyfile/directives/tls)
- `virtual.tls` (alias of `virtual.tls-email`) could be empty, unset or set to a [valid set of tls directive value(s)](https://caddyserver.com/docs/caddyfile/directives/tls)
- `virtual.auth.username` when set, along with `virtual.auth.password` and `virtual.auth.path`, http basic authentication is enabled
- `virtual.auth.password` needs to be specified, along with `virtual.auth.usernmae`, to enable http [basic authentication](https://caddyserver.com/docs/caddyfile/directives/basicauth)
- `virtual.auth.path` sets path basic auth applys to.

Note, that options should not differ for containers of a single service.

### Backing up certificates

To backup certificates make a volume:

```yaml
services:
  caddy:
    volumes:
      - ./caddy-info:/data/caddy
```

### Versions

This image supports two [build-time](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg) arguments:

- `FOREGO_VERSION` to change the current version of [`forego`](https://github.com/jwilder/forego/releases)
- `DOCKER_GEN_VERSION` to change the current version of [`docker-gen`](https://github.com/jwilder/docker-gen/releases)

## See also

- Raw `Caddy` [image](https://github.com/wemake-services/caddy-docker)
- [Django project template](https://github.com/wemake-services/wemake-django-template) with `Caddy`
- Tool to limit your `docker` [image size](https://github.com/wemake-services/docker-image-size-limit)

## Changelog

Full changelog is available [here](https://github.com/wemake-services/caddy-gen/blob/master/CHANGELOG.md).

## License

MIT. See [LICENSE](https://github.com/wemake-services/caddy-gen/blob/master/LICENSE) for more details.
