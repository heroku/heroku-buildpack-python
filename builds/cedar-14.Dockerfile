FROM heroku/cedar:14

WORKDIR /app
ENV WORKSPACE_DIR="/app/builds" \
    S3_BUCKET="lang-python" \
    S3_PREFIX="cedar-14/" \
    DEBIAN_FRONTEND=noninteractive \
    STACK="cedar-14"

RUN apt-get update && apt-get install -y python-pip && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install -r /app/requirements.txt

COPY . /app
