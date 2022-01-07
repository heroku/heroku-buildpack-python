# Python Buildpack Binaries

To get started with it, create an app on Scalingo inside a clone of this repository, and set your S3 config vars:

```
  $ scalingo create hack-python-buildpack
  $ scalingo env-set BUILDPACK_URL=https://github.com/Scalingo/python-buildpack
  $ scalingo env-set WORKSPACE_DIR=builds
  $ scalingo env-set AWS_ACCESS_KEY_ID=<your_aws_key>
  $ scalingo env-set AWS_SECRET_ACCESS_KEY=<your_aws_secret>
  $ scalingo env-set S3_BUCKET=<your_s3_bucket_name>
```

In addition, unless you are building the official binaries for Heroku (which use the defaults
specified in each `Dockerfile`), you will need to override `S3_BUCKET` and `S3_PREFIX` to
match your own S3 bucket/use case.

    $ scalingo run bash
    ~ $ bob build runtimes/python-2.7.6

For example:

```bash
set +o history # Disable bash history
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
set -o history # Re-enable bash history
make ...
```

If you need to override the default S3 bucket, or would prefer not to use credentials via
environment variables, then you need to instead use a Docker env file like so:

To speed things up drastically, it'll usually be a good idea to `scalingo run bash --size 2XL` instead.

   ```bash
   make ... ENV_FILE=~/.dockerenv.python-buildpack
   ```

## Launching an interactive build environment

To start an interactive version of the build environment (ideal for development) use the
`buildenv` make target, passing in the desired `STACK` name. For example:

```bash
make buildenv STACK=heroku-18
```

This will create the builder docker image based on the latest image for that stack, and
then start a bash shell where you can run `bob build`, `bob deploy`, and so forth.

The `builds/` directory is bind-mounted into the running container, so local build formula
changes will appear there immediately without the need to rebuild the image.

## Bulk deploying runtimes

When a new Python version is released, binaries have to be generated for multiple stacks.
To automate this, use the `deploy-runtimes` make target, which will ensure the builder
image is up to date, and then run `bob deploy` for each runtime-stack combination.

The build formula name(s) are passed using `RUNTIMES`, like so:

```bash
make deploy-runtimes RUNTIMES='python-X.Y.Z'
```

By default this will deploy to all supported stacks (see `STACKS` in `Makefile`),
but this can be overridden using `STACKS`:

```bash
make deploy-runtimes RUNTIMES='python-X.Y.Z' STACKS='heroku-18'
```

Multiple runtimes can also be specified (useful for when adding a new stack), like so:

```bash
make deploy-runtimes RUNTIMES='python-A.B.C python-X.Y.Z' STACKS='heroku-20'
```

Note: Both `RUNTIMES` and `STACKS` are space delimited.
