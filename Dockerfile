# syntax=docker/dockerfile:1.4
FROM ubuntu:22.04@sha256:67211c14fa74f070d27cc59d69a7fa9aeff8e28ea118ef3babc295a0428a6d21 as dev

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG USER=dev
ARG UID=1000
ARG HOME_DIR=/home/${USER}
ARG WORK_DIR=/app

ENV ORIGINAL_PATH=$PATH
SHELL ["/bin/bash", "-exuo", "pipefail", "-c"]

#------------------------------------
#  Set up WORKDIR
#------------------------------------
WORKDIR ${WORK_DIR}

#------------------------------------
#  Install apt packages
#------------------------------------
# hadolint ignore=DL3008,DL3009
RUN apt-get update && \
  # Install packages
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  # Trusted root certificates
  ca-certificates \
  # Misc linux utilities
  sudo \
  tree \
  vim \
  less \
  unzip \
  # For web interaction
  httpie \
  curl \
  jq \
  # Git interaction with GitHub
  git \
  openssh-client \
  # Commit signing
  gnupg2 \
  gpg-agent \
  dirmngr \
  # Shell script linter, also used by actionlint
  shellcheck \
  && \
  find /var/lib/apt/lists -delete -mindepth 1

#------------------------------------
# Set up Git for development
#------------------------------------
RUN git config --system --add safe.directory ${WORK_DIR} && \
  git init --quiet ${WORK_DIR}

#------------------------------------
#  Create non-root user
#------------------------------------
# SC2016: $PATH is meant literally here
# hadolint ignore=SC2016
RUN groupadd --gid $UID $USER && \
  useradd --uid $UID -m --gid $UID -s /bin/bash $USER && \
  chown ${USER}:${USER} ${WORK_DIR} && \
  # the user needs to be able to chown the ssh socket later
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
  # Alias sudo so that the env vars are inherited from the calling user
  echo 'alias sudo="sudo --preserve-env env PATH=$PATH"' >> $HOME_DIR/.bash_aliases && \
  chown ${USER}:${USER} $HOME_DIR/.bash_aliases

#------------------------------------
#  Install nodeenv
#------------------------------------
# renovate: datasource=github-releases depName=nodenv/nodenv
ARG NODENV_VERSION=v1.4.1
# renovate: datasource=github-releases depName=nodenv/node-build
ARG NODE_BUILD_VERSION=v4.9.113
ENV NODENV_ROOT="/usr/local/nodenv"
ENV PATH="${NODENV_ROOT}/shims:${NODENV_ROOT}/bin:${PATH}"
RUN git clone -b "${NODENV_VERSION}" --single-branch https://github.com/nodenv/nodenv.git ${NODENV_ROOT} && \
  mkdir -p "${NODENV_ROOT}/plugins" && \
  git clone -b "${NODE_BUILD_VERSION}" --single-branch https://github.com/nodenv/node-build.git "${NODENV_ROOT}/plugins/node-build"

#------------------------------------
#  Install Node
#------------------------------------
ARG NODE_VERSION=18.16.0
ENV NODENV_VERSION=${NODE_VERSION}
RUN \
  # Set this env var so that root sees it inside the container
  echo "export NODEENV_VERSION=${NODENV_VERSION}" >> /root/.bashrc && \
  nodenv install ${NODE_VERSION} && \
  eval "$(nodenv init -)"

#------------------------------------
#  Install Yarn
#------------------------------------
ARG YARN_VERSION=1.22.19
ENV PATH="${WORK_DIR}/node_modules/.bin:${PATH}"
RUN corepack enable && \
  corepack prepare "yarn@${YARN_VERSION}" --activate && \
  nodenv rehash

#------------------------------------
#  Install Node packages
#------------------------------------
#COPY yarn.lock .
#RUN yarn install --immutable --immutable-cache --check-cache --inline-builds

#------------------------------------
#  Install fixuid
#------------------------------------
# renovate: datasource=github-releases depName=boxboat/fixuid
ARG FIXUID_VERSION=v0.5.1
RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/${FIXUID_VERSION}/fixuid-${FIXUID_VERSION#v}-${TARGETOS}-${TARGETARCH}.tar.gz | \
  tar -C /usr/local/bin -xzf - && \
  chown root:root /usr/local/bin/fixuid && \
  chmod 4755 /usr/local/bin/fixuid && \
  mkdir -p /etc/fixuid && \
  printf "user: %s\ngroup: %s\npaths:\n  - %s\n" "$USER" "$USER" "$HOME_DIR" > /etc/fixuid/config.yml

#------------------------------------
#  Install hadolint
#------------------------------------
# renovate: datasource=github-releases depName=hadolint/hadolint
ARG HADOLINT_VERSION=v2.12.0
RUN \
  case $TARGETPLATFORM in \
  linux/amd64) \
  hadolint_platform=Linux-x86_64;; \
  linux/arm64) \
  hadolint_platform=Linux-arm64;; \
  esac && \
  curl -sSL https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-${hadolint_platform} > /usr/local/bin/hadolint && \
  chmod 755 /usr/local/bin/hadolint

#------------------------------------
#  Install actionlint
#------------------------------------
# renovate: datasource=github-releases depName=rhysd/actionlint
ARG ACTIONLINT_VERSION=v1.6.24
RUN \
  curl -sSL https://github.com/rhysd/actionlint/releases/download/${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION#v}_${TARGETOS}_${TARGETARCH}.tar.gz | \
  tar -C /usr/local/bin -xzf - && \
  chmod 755 /usr/local/bin/actionlint

#------------------------------------
#  Install shfmt
#------------------------------------
# renovate: datasource=github-releases depName=mvdan/sh
ARG SHFMT_VERSION=v3.6.0
RUN curl -sSL https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_${TARGETOS}_${TARGETARCH} > /usr/local/bin/shfmt && \
  chmod 755 /usr/local/bin/shfmt

#------------------------------------
#  Finish up as root
#------------------------------------
# SC2016: The second $PATH is meant literally here
# hadolint ignore=SC2016
RUN  \
  # export PATH=/foo/bar:${PATH}
  echo 'export PATH='${PATH%"${ORIGINAL_PATH}"}'${PATH}' >> /root/.bashrc && \
  chown -R ${USER}:${USER} ${HOME_DIR}

#------------------------------------
#  Switch to non-root user
#------------------------------------
USER ${USER}:${USER}

#------------------------------------
# Set ENTRYPOINT and CMD
#------------------------------------
ENTRYPOINT [ "fixuid", "-q" ]
#CMD [ "yarn", "start:dev" ]

#------------------------------------
# Configure environment
#------------------------------------
ENV PAGER=/usr/bin/less
ENV EDITOR=/usr/bin/vim
