FROM caddy:2.11.2-alpine

ARG DOCKER_GEN_VERSION="0.14.0"
ARG FOREGO_VERSION="0.16.1"

ENV CADDYPATH="/etc/caddy"
ENV DOCKER_HOST="unix:///tmp/docker.sock"

# Install all dependenices:
RUN apk update && apk upgrade \
  && apk add --no-cache bash openssh-client git shadow shadow-login sudo \
  && apk add --no-cache --virtual .build-dependencies curl tar \
  # Install Forego
  && curl -fsSLo /usr/bin/forego "https://github.com/jwilder/forego/releases/download/v${FOREGO_VERSION}/forego" \
  && chmod a+x /usr/bin/forego \
  # Install docker-gen
  && curl -fsSL "https://github.com/nginx-proxy/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz" \
   | tar -C /usr/bin -xvzf - \
  && apk del .build-dependencies

EXPOSE 80 443 2015
VOLUME /etc/caddy

# Starting app:
COPY . /code
COPY ./docker-gen/templates/Caddyfile.tmpl /code/docker-gen/templates/Caddyfile.bkp
WORKDIR /code

# Create caddy user
ARG CADDY_USER=caddy
ARG CADDY_GROUP=caddy
ARG CADDY_UID=1000
ARG CADDY_GID=100
ENV CADDY_USER=${CADDY_USER} \
  CADDY_GROUP=${CADDY_GROUP} \
  CADDY_UID=${CADDY_UID} \
  CADDY_GID=${CADDY_GID}
RUN if grep -q "${CADDY_UID}" /etc/passwd; then \
  userdel --remove $(id -un "${CADDY_UID}"); fi
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su \
  && sed -e 's/^%admin/#%admin/' -e 's/^%sudo/#%sudo/' -i /etc/sudoers \
  && useradd --no-log-init --create-home --shell /bin/bash --uid "${CADDY_UID}" --no-user-group "${CADDY_USER}"
RUN chown -R "${CADDY_UID}:${CADDY_GID}" \
  /etc/caddy /config/caddy /code/docker-gen/templates/Caddyfile.tmpl
USER ${CADDY_UID}

ENTRYPOINT ["sh", "/code/docker-entrypoint.sh"]
CMD ["/usr/bin/forego", "start", "-r"]
