ARG STACK_VERSION="24"
FROM ghcr.io/sigstore/cosign/cosign:v2.6.1@sha256:68839b7f13dac5a6744a5d8818e984dd39183374e37855c19e14d623d9bc9037 AS cosign
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
