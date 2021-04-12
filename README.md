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

## Configuration / Options

`caddy-gen` is configured with [`labels`](https://docs.docker.com/engine/userguide/labels-custom-metadata/).

The main idea is simple.
Every labeled service exposes a `virtual.host` to be handled.
Then, every container represents a single `upstream` to serve requests.

NOTE: Caddy2 was introduced in [version 0.3.0](https://github.com/wemake-services/caddy-gen/releases/tag/0.3.0) causing BREAKING CHANGES.

Main configuration options:

- `virtual.host` (required) domain name, don't pass `http://` or `https://`, you can separate them with spaces.
- `virtual.alias` domain alias, useful for `www` prefix with redirect. For example `www.myapp.com`. Alias will always redirect to the host above.
- `virtual.port` port exposed by container, e.g. `3000` for React apps in development.
- `virtual.tls-email` the email address to use for the ACME account managing the site's certificates (required to enable HTTPS).
- `virtual.tls` alias of `virtual.tls-email`.
- `virtual.host.directives` set custom [Caddyfile directives](https://caddyserver.com/docs/caddyfile/directives) for the host. These will be inlined into the site block.
- `virtual.host.import` include Caddyfile directives for the host from a file on the container's filesystem. See [Caddy import](https://caddyserver.com/docs/caddyfile/directives/import).

[Basic authentication](https://caddyserver.com/docs/caddyfile/directives/basicauth) options:
- `virtual.auth.path` with
- `virtual.auth.username` and
- `virtual.auth.password` together enable HTTP basic authentication. (Password should be a string `base64` encoded from `bcrypt` hash. You can use https://bcrypt-generator.com/ with default config and https://www.base64encode.org/.)

[Reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy) options:
- `virtual.proxy.matcher` have the reverse proxy only match certain paths.
- `virtual.proxy.lb_policy` specify load balancer policy, defaults to `round_robin`.
- `virtual.proxy.directives` include any reverse_proxy directives. These will be inlined into the reverse proxy block.
- `virtual.proxy.import` include any reverse_proxy directives from a file on the container's filesystem. See [Caddy import](https://caddyserver.com/docs/caddyfile/directives/import).

To include a custom template:
- mount a volume containing your custom template and/or snippet (they both may
  be Go templates and will be loaded by `docker-gen`).
- set the environment variable `CADDY_TEMPLATE` to the mounted file containining
  your custom Caddyfile template. This will replace the default template.
- set the environment variable `CADDY_SNIPPET` to the mounted file containining
  your custom Caddyfile snippet. This will be prepended to the caddy template,
  so you may use it to set [Global Options](https://caddyserver.com/docs/caddyfile/options),
  define [snippet blocks](https://caddyserver.com/docs/caddyfile/concepts#snippets),
  or [add custom address blocks](https://caddyserver.com/docs/caddyfile/concepts).
- See [example "Use a custom Caddy template for `docker-gen`"](#use-a-custom-caddy-template-for-docker-gen)

### Version build-time arguments

This image supports two [build-time](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg) arguments:

- `FOREGO_VERSION` to change the current version of [`forego`](https://github.com/jwilder/forego/releases)
- `DOCKER_GEN_VERSION` to change the current version of [`docker-gen`](https://github.com/jwilder/docker-gen/releases)

## Usage

Caddy-gen is created to be used in a single container. It will act as a reverse
proxy for the whoami service.

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
      - "virtual.auth.path=/secret/*" # path basic authentication applies to
      - "virtual.auth.username=admin" # Optionally add http basic authentication
      - "virtual.auth.password=JDJ5JDEyJEJCdzJYM0pZaWtMUTR4UVBjTnRoUmVJeXQuOC84QTdMNi9ONnNlbDVRcHltbjV3ME1pd2pLCg==" # By specifying both username and password hash
```

See [`docker-compose.yml`](https://github.com/wemake-services/caddy-gen/blob/master/example/docker-compose.yml) example file.

### Backing up certificates

To backup certificates make a volume:

```yaml
services:
  caddy:
    volumes:
      - ./caddy-info:/data/caddy
```

### Add or modify reverse_proxy headers 

With the following settings, the upstream host will see its own address instead
of the original incoming value. See [Headers](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#headers).

```yaml
version: "3"
services:
  caddy-gen:
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

  whoami:
    image: "katacoda/docker-http-server:v2"
    labels:
      virtual.host: myapp.com
      virtual.port: 80
      virtual.tls: admin@myapp.com
      virtual.proxy.directives: |
        header_up Host {http.reverse_proxy.upstream.hostport}
```

### Set up a static file server for a host

With the following settings, myapp.com will serve files from directory `www`
and only requests to `/api/*` will be routed to the whoami service.  See
[file_server](https://caddyserver.com/docs/caddyfile/directives/file_server).

```yaml
version: "3"
services:
  caddy-gen:
    image: "wemakeservices/caddy-gen:latest"
    restart: always
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro # needs socket to read events
      - ./caddy-info:/data/caddy # needs volume to back up certificates
      - ./www:/srv/myapp/www # files served by myapp.com
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - whoami

  whoami:
    image: "katacoda/docker-http-server:v2"
    labels:
      virtual.host: myapp.com
      virtual.port: 80
      virtual.tls: admin@myapp.com
      virtual.proxy.matcher: /api/*
      virtual.host.directives: |
        root * /srv/myapp/www
        templates
        file_server
```

### Use a custom Caddy template for `docker-gen`

With this custom template, Caddy-gen will act as a reverse proxy for service
containers and store their logs under the appropriate host folder in
`/var/logs`.

```jinja
# file: ./caddy/template
(redirectHttps) {
  @http {
    protocol http
  }
  redir @http https://{host}{uri}
}

(logFile) {
  log {
    output file /var/caddy/{host}/logs {
      roll_keep_for 7
    }
  }
}

{{ $hosts := groupByLabel $ "virtual.host" }}
{{ range $h, $containers := $hosts }}
{{ range $t, $host := split (trim (index $c.Labels "virtual.host")) " " }}
{{ $tls = trim (index $c.Labels "virtual.tls") }}
{{ $host }} {
  {{ if $tls }}
  tls {{ $tls }}
  import redirectHttps
  {{ end }}
  reverse_proxy {
    lb_policy round_robin
    {{ range $i, $container := $containers }}
    {{ range $j, $net := $container.Networks }}
    to {{ $net.IP}}:{{ or (trim (index $container.Labels "virtual.port")) "80" }}
    {{ end }}
    {{ end }}
  }
  encode zstd gzip
  import logFile
}
```

```yaml
# file: docker-compose.yml
services:
  caddy-gen:
    volumes:
      # mount the template file into the container
      - ./caddy/template:/tmp/caddy/template
    environment:
      # CADDY_TEMPLATE will replace the default caddy template
      CADDY_TEMPLATE: /tmp/caddy/template
```

### Set [global options](https://caddyserver.com/docs/caddyfile/options) for Caddy

With this snippet, Caddy will request SSL certificates from the [Let's Encrypt
staging environment](https://letsencrypt.org/docs/staging-environment/). This
is [useful for testing](https://caddyserver.com/docs/automatic-https#testing)
without running up against rate limits when you want to deploy.

```jinja
# file: ./caddy/global_options
{
  acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}
```

```yaml
# file: docker-compose.yml
services:
  caddy-gen:
    volumes:
      # mount the template file into the container
      - ./caddy/global_options:/tmp/caddy/global_options
    environment:
      # CADDY_SNIPPET will prepend to the default caddy template
      CADDY_SNIPPET: /tmp/caddy/global_options
```

## See also

- Raw `Caddy` [image](https://github.com/wemake-services/caddy-docker)
- [Django project template](https://github.com/wemake-services/wemake-django-template) with `Caddy`
- Tool to limit your `docker` [image size](https://github.com/wemake-services/docker-image-size-limit)

## Changelog

Full changelog is available [here](https://github.com/wemake-services/caddy-gen/blob/master/CHANGELOG.md).

## License

MIT. See [LICENSE](https://github.com/wemake-services/caddy-gen/blob/master/LICENSE) for more details.
