FROM alpine:3.11.2

LABEL maintainer="Nikita Sobolev <sobolevn@wemake.services>"
LABEL vendor="wemake.services"
LABEL version="0.2.0"

ARG CADDY_VERSION="0.10.12"
ARG FOREGO_VERSION="0.16.1"
ARG DOCKER_GEN_VERSION="0.7.4"

ENV CADDYPATH="/etc/caddy"
ENV DOCKER_HOST="unix:///tmp/docker.sock"


# Install all dependenices:
RUN apk update && apk upgrade \
  && apk add --no-cache bash openssh-client git \
  && apk add --no-cache --virtual .build-dependencies curl wget tar \
  # Install Forego
  && wget --quiet "https://github.com/jwilder/forego/releases/download/v${FOREGO_VERSION}/forego" \
  && mv ./forego /usr/bin/forego \
  && chmod u+x /usr/bin/forego \
  # Install docker-gen
  && wget --quiet "https://github.com/jwilder/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  && tar -C /usr/bin -xvzf "docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  && rm "/docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  # Install Caddy
  && curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://github.com/mholt/caddy/releases/download/v${CADDY_VERSION}/caddy_v${CADDY_VERSION}_linux_amd64.tar.gz" \
    | tar --no-same-owner -C /usr/bin -xz \
  && chmod 0755 /usr/bin/caddy \
  && /usr/bin/caddy -version \
  && apk del .build-dependencies

EXPOSE 80 443 2015
VOLUME /etc/caddy


# Starting app:

COPY . /code
WORKDIR /code

ENTRYPOINT ["sh", "/code/docker-entrypoint.sh"]
CMD ["/usr/bin/forego", "start", "-r"]
