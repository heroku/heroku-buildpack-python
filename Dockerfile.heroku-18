FROM heroku/heroku:18-build

WORKDIR /app
ENV WORKSPACE_DIR="/app/builds" \
    S3_BUCKET="lang-python" \
    S3_PREFIX="heroku-18/"

RUN apt-get update && apt-get install -y python-pip && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --disable-pip-version-check --no-cache-dir -r /app/requirements.txt

COPY . /app
