ARG STACK_VERSION="24"
FROM ghcr.io/sigstore/cosign/cosign:v3.1.4@sha256:0f06154836d2de34f887a5c273506d52ca43edaa1d9e53e6510fa78a48f69c2d AS cosign
FROM heroku/heroku:${STACK_VERSION}-build

ARG STACK_VERSION
ENV STACK="heroku-${STACK_VERSION}"

# For Heroku-24 and newer, the build image sets a non-root default `USER`.
USER root

# `libcrypt-dev` can be removed once we drop support for Python 3.12,
# since the `crypt` module was removed in Python 3.13:
# https://docs.python.org/3.13/whatsnew/3.13.html#whatsnew313-pep594
RUN apt-get update --error-on=any \
    && apt-get install -y --no-install-recommends \
      libcrypt-dev \
      libdb-dev \
      libreadline-dev \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign

WORKDIR /tmp
COPY build_python_runtime.sh .
