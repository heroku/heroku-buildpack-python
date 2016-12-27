FROM heroku/heroku:16-build

WORKDIR /app
ENV WORKSPACE_DIR=/app/builds

RUN apt-get update && apt-get install -y python-pip

# Install bob-builder application
RUN pip install bob-builder==0.0.5

COPY . /app