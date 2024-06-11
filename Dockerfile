FROM caddy:2.8.4-alpine

ARG DOCKER_GEN_VERSION="0.14.0"
ARG FOREGO_VERSION="0.16.1"

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
  && wget --quiet "https://github.com/nginx-proxy/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  && tar -C /usr/bin -xvzf "docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  && rm "docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
  && apk del .build-dependencies

EXPOSE 80 443 2015
VOLUME /etc/caddy

# Starting app:
COPY . /code
COPY ./docker-gen/templates/Caddyfile.tmpl /code/docker-gen/templates/Caddyfile.bkp
WORKDIR /code

ENTRYPOINT ["sh", "/code/docker-entrypoint.sh"]
CMD ["/usr/bin/forego", "start", "-r"]
