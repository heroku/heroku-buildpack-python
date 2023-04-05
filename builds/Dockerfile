ARG STACK_VERSION="22"
FROM --platform=linux/amd64 heroku/heroku:${STACK_VERSION}-build

ARG STACK_VERSION
ENV STACK="heroku-${STACK_VERSION}"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
COPY build_python_runtime.sh .
