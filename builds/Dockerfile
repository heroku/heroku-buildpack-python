ARG STACK_VERSION="24"
FROM ghcr.io/sigstore/cosign/cosign:v3.0.3@sha256:774391ac9f0c137ee419ce56522df5fd3b1f52be90c5b77e97f7c053bdd67a67 AS cosign
FROM heroku/heroku:${STACK_VERSION}-build

ARG STACK_VERSION
ENV STACK="heroku-${STACK_VERSION}"

# For Heroku-24 and newer, the build image sets a non-root default `USER`.
USER root

RUN apt-get update --error-on=any \
    && apt-get install -y --no-install-recommends \
      libdb-dev \
      libreadline-dev \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign

WORKDIR /tmp
COPY build_python_runtime.sh .
