ARG STACK_VERSION="24"
FROM ghcr.io/sigstore/cosign/cosign:v3.0.5@sha256:be924970ba7438c22e18067dec5637946d6566eac711f5bedd1584e7137008fb AS cosign
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
