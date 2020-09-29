FROM heroku/cedar:14

ENV WORKSPACE_DIR="/app/builds" \
    S3_BUCKET="lang-python" \
    S3_PREFIX="cedar-14/" \
    STACK="cedar-14"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        libsqlite3-dev \
        python3-pip \
        realpath \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/
# Can't use `--disable-pip-version-check --no-cache-dir` since not supported by Ubuntu 14.04's pip.
RUN pip3 install -r /app/requirements.txt

COPY . /app
