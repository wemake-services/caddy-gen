#!/bin/bash
set -euo pipefail

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

# Create initial configuration
docker-gen /code/docker-gen/templates/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command based on https://github.com/jupyter/docker-stacks/blob/64b506080403b73c3d5805c76fd1d1966bd4cdd4/images/docker-stacks-foundation/Dockerfile
if [ "$(id -u)" == 0 ]; then
  # Environment variables:
  # - CADDY_USER: the desired username and associated home folder
  # - CADDY_UID: the desired user id
  # - CADDY_GID: a group id we want our user to belong to
  # - CADDY_GROUP: a group name we want for the group
  # - CHOWN_HOME: a boolean ("1" or "yes") to chown the user's home folder
  # - CHOWN_EXTRA: a comma-separated list of paths to chown
  # - CHOWN_HOME_OPTS / CHOWN_EXTRA_OPTS: arguments to the chown commands

  # Refit the caddy user to the desired user (CADDY_USER)
  if id caddy &> /dev/null; then
    if ! usermod --home "/home/${CADDY_USER}" --login "${CADDY_USER}" caddy 2>&1 | grep "no changes" > /dev/null; then
      echo >&2 "Updated the caddy user:"
      echo >&2 "- username: caddy       -> ${CADDY_USER}"
      echo >&2 "- home dir: /home/caddy -> /home/${CADDY_USER}"
    fi
  elif ! id -u "${CADDY_USER}" &> /dev/null; then
    echo >&2 "ERROR: Neither the caddy user nor '${CADDY_USER}' exists. This could be the result of stopping and starting, the container with a different CADDY_USER environment variable."
    exit 1
  fi
  # Ensure the desired user (CADDY_USER) gets its desired user id (CADDY_UID) and is a member of the desired group (CADDY_GROUP, CADDY_GID)
  if [ "${CADDY_UID}" != "$(id -u "${CADDY_USER}")" ] || [ "${CADDY_GID}" != "$(id -g "${CADDY_USER}")" ]; then
    echo >&2 "Update ${CADDY_USER}'s UID:GID to ${CADDY_UID}:${CADDY_GID}"
    if [ "${CADDY_GID}" != "$(id -g "${CADDY_USER}")" ]; then
      groupadd --force --gid "${CADDY_GID}" --non-unique "${CADDY_GROUP:-${CADDY_USER}}"
    fi
    userdel "${CADDY_USER}"
    useradd --no-log-init --home "/home/${CADDY_USER}" --shell /bin/bash --uid "${CADDY_UID}" --gid "${CADDY_GID}" --groups 100 "${CADDY_USER}"
  fi
  # Update the home directory if the desired user (CADDY_USER) is root and the desired user id (CADDY_UID) is 0 and the desired group id (CADDY_GID) is 0.
  if [ "${CADDY_USER}" = "root" ] && [ "${CADDY_UID}" = "$(id -u "${CADDY_USER}")" ] && [ "${CADDY_GID}" = "$(id -g "${CADDY_USER}")" ]; then
    sed -i "s|/root|/home/root|g" /etc/passwd
    CP_OPTS="-a --no-preserve=ownership"
  fi
  # Move or symlink the caddy home directory to the desired user's home directory if it doesn't already exist, and update the current working directory to the new location if needed.
  if [[ "${CADDY_USER}" != "caddy" ]]; then
    if [[ ! -e "/home/${CADDY_USER}" ]]; then
      echo >&2 "Attempting to copy /home/caddy to /home/${CADDY_USER}..."
      mkdir "/home/${CADDY_USER}"
      if cp ${CP_OPTS:--a} /home/caddy/. "/home/${CADDY_USER}/"; then
        echo >&2 "Success!"
      else
        echo >&2 "Failed to copy data from /home/caddy to /home/${CADDY_USER}!"
        echo >&2 "Attempting to symlink /home/caddy to /home/${CADDY_USER}..."
        if ln -s /home/caddy "/home/${CADDY_USER}"; then
          echo >&2 "Success creating symlink!"
        else
          echo >&2 "ERROR: Failed copy data from /home/caddy to /home/${CADDY_USER} or to create symlink!"
          exit 1
        fi
      fi
    fi
    if [[ "${PWD}/" == "/home/caddy/"* ]]; then
      new_wd="/home/${CADDY_USER}/${PWD:12}"
      echo >&2 "Changing working directory to ${new_wd}"
      cd "${new_wd}"
    fi
  fi
  # Optionally ensure the desired user gets filesystem ownership of its home folder and/or additional folders
  if [[ "${CHOWN_HOME:-}" == "1" || "${CHOWN_HOME:-}" == "yes" ]]; then
    echo >&2 "Ensuring /home/${CADDY_USER} is owned by ${CADDY_UID}:${CADDY_GID} ${CHOWN_HOME_OPTS:+(chown options: ${CHOWN_HOME_OPTS})}"
    chown ${CHOWN_HOME_OPTS:-} "${CADDY_UID}:${CADDY_GID}" "/home/${CADDY_USER}"
  fi
  if [ -n "${CHOWN_EXTRA:-}" ]; then
    for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
      echo >&2 "Ensuring ${extra_dir} is owned by ${CADDY_UID}:${CADDY_GID} ${CHOWN_EXTRA_OPTS:+(chown options: ${CHOWN_EXTRA_OPTS})}"
      chown ${CHOWN_EXTRA_OPTS:-} "${CADDY_UID}:${CADDY_GID}" "${extra_dir}"
    done
  fi
  echo >&2 "Running as ${CADDY_USER}:" "$@"
  if [ "${CADDY_USER}" = "root" ] && [ "${CADDY_UID}" = "$(id -u "${CADDY_USER}")" ] && [ "${CADDY_GID}" = "$(id -g "${CADDY_USER}")" ]; then
    HOME="/home/root" exec "$@"
  else
    exec sudo --preserve-env --set-home --user "${CADDY_USER}" \
      PATH="${PATH}" \
      "$@"
  fi
# The container didn't start as the root user, so we will have to act as the user we started as.
else
  caddy_UID="$(id -u caddy 2>/dev/null)"  # The default UID for the caddy user
  caddy_GID="$(id -g caddy 2>/dev/null)"  # The default GID for the caddy user

  # Attempt to ensure the user uid we currently run as has a named entry in the /etc/passwd file, as it avoids software crashing on hard assumptions on such entry.
  # Writing to the /etc/passwd was allowed for the root group from the Dockerfile during the build.
  if ! whoami &> /dev/null; then
    echo >&2 "There is no entry in /etc/passwd for our UID=$(id -u). Attempting to fix..."
    if [[ -w /etc/passwd ]]; then
      echo >&2 "Renaming old caddy user to yddac ($(id -u caddy):$(id -g caddy))"
      sed --expression="s/^caddy:/yddac:/" /etc/passwd > /tmp/passwd
      echo "${CADDY_USER}:x:$(id -u):$(id -g):,,,:/home/caddy:/bin/bash" >> /tmp/passwd
      cat /tmp/passwd > /etc/passwd
      rm /tmp/passwd
      echo >&2 "Added new ${CADDY_USER} user ($(id -u):$(id -g)). Fixed UID!"
      if [[ "${CADDY_USER}" != "caddy" ]]; then
        echo >&2 "WARNING: user is ${CADDY_USER} but home is /home/caddy. You must run as root to rename the home directory!"
      fi
    else
      echo >&2 "WARNING: unable to fix missing /etc/passwd entry because we don't have write permission. Try setting gid=0 with \"--user=$(id -u):0\"."
    fi
  fi
  # Warn about misconfiguration
  if [[ "${CADDY_USER}" != "caddy" && "${CADDY_USER}" != "$(id -un)" ]]; then
    echo >&2 "WARNING: container must be started as root to change the desired user's name with CADDY_USER=\"${CADDY_USER}\"!"
  fi
  if [[ "${CADDY_UID}" != "${caddy_UID}" && "${CADDY_UID}" != "$(id -u)" ]]; then
    echo >&2 "WARNING: container must be started as root to change the desired user's id with CADDY_UID=\"${CADDY_UID}\"!"
  fi
  if [[ "${CADDY_GID}" != "${caddy_GID}" && "${CADDY_GID}" != "$(id -g)" ]]; then
    echo >&2 "WARNING: container must be started as root to change the desired user's group id with CADDY_GID=\"${CADDY_GID}\"!"
  fi
  if [[ ! -w /home/caddy ]]; then
    echo >&2 "WARNING: no write access to /home/caddy. Try starting the container with group 'users' (100), e.g. using \"--group-add=users\"."
  fi
  echo >&2 "Executing the command:" "$@"
  exec "$@"
fi
