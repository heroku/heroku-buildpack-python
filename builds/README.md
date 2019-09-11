# Python Buildpack Binaries

## Building the Docker Images

**After every change to your formulae, perform the following** from the root of the Git repository (not from `builds/`) to rebuild the images for each stack:

    $ docker build --pull --tag heroku-python-build-cedar-14 --file $(pwd)/builds/cedar-14.Dockerfile .
    $ docker build --pull --tag heroku-python-build-heroku-16 --file $(pwd)/builds/heroku-16.Dockerfile .
    $ docker build --pull --tag heroku-python-build-heroku-18 --file $(pwd)/builds/heroku-18.Dockerfile .

## Using the Image

You can e.g. `bash` into each of the images you built using their tag:

    docker run --rm -ti heroku-python-build-cedar-14 bash
    docker run --rm -ti heroku-python-build-heroku-16 bash
    docker run --rm -ti heroku-python-build-heroku-18 bash

You then have a shell where you can run `bob build`, `bob deploy`, and so forth. You can of course also invoke these programs directly with `docker run`:

    docker run --rm -ti heroku-python-build-heroku-18 bob build runtimes/python-2.7.15

In order to `bob deploy`, AWS credentials must be set up, as well as name and prefix of your custom S3 bucket (unless you're deploying to the Heroku production buckets that are pre-defined in each `Dockerfile`); see next section for details.

## Configuration

File `dockerenv.default` contains a list of required env vars; most of these have default values defined in `Dockerfile`. You can copy this file to a location outside the buildpack and modify it with the values you desire and pass its location with `--env-file`, or pass the env vars to `docker run` using `--env`.

Out of the box, each `Dockerfile` has the correct values predefined for `S3_BUCKET`, `S3_PREFIX`, and `S3_REGION`. If you're building your own packages, you'll likely want to change `S3_BUCKET` and `S3_PREFIX` to match your info. Instead of setting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` into that file, you may also pass them to `docker run` through the environment, or explicitly using `--env`, in order to prevent accidental commits of credentials.

### Passing AWS credentials to the container

If you want to deploy packages and thus need to pass `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, you can either pass them explicitly, through your environment, or through an env file.

#### Passing credentials explicitly

    docker run --rm -ti -e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=... heroku-python-build-heroku-18 bash

#### Passing credentials through  the environment

The two environment variables `AWS_ACCESS_KEY_ID`and `AWS_SECRET_ACCESS_KEY` are defined in `builds/dockerenv.default`, without values. This will cause Docker to "forward" values for these variables from the current environment, so you can pass them in:

    AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... docker run --rm -ti --env-file=builds/dockerenv.default heroku-python-build-heroku-18 bash

or

    export AWS_ACCESS_KEY_ID=...
    export AWS_SECRET_ACCESS_KEY=...
    docker run --rm -ti --env-file=builds/dockerenv.default heroku-python-build-heroku-18 bash

#### Passing credentials through a separate env file

This method is the easiest for users who want to build packages in their own S3 bucket, as they will have to adjust the `S3_BUCKET` and `S3_PREFIX` environment variable values anyway from their default values.

For this method, it is important to keep the credentials file in a location outside the buildpack, so that your credentials aren't accidentally committed. Copy `builds/dockerenv.default` **to a safe location outside the buildpack directory**, and insert your values for `AWS_ACCESS_KEY_ID`and `AWS_SECRET_ACCESS_KEY`.

    docker run --rm -ti --env-file=../SOMEPATHOUTSIDE/s3.env heroku-python-build-heroku-18 bash
