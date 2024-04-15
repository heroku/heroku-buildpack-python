ARG STACK_VERSION="22"
FROM heroku/heroku:${STACK_VERSION}-build

ARG STACK_VERSION
ENV STACK="heroku-${STACK_VERSION}"

RUN apt-get update --error-on=any \
    && apt-get install -y --no-install-recommends \
      libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
COPY build_python_runtime.sh .
