# Python Buildpack Binaries

The binaries for this buildpack are built in Docker containers based on the Heroku stack image.

## Configuration

In order to publish binaries AWS credentials must be passed to the build container.
If you are testing only the build (ie: `bob build`), these are optional.

In addition, unless you are building the official binaries for Heroku (which use the defaults
specified in each `Dockerfile`), you will need to override `S3_BUCKET` and `S3_PREFIX` to
match your own S3 bucket/use case.

If you only need to set AWS credentials, you can do so by setting the environment variables
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` before calling the make commands.

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

1. Copy the `builds/dockerenv.default` env file to a location outside the buildpack repository.
2. Edit the new file, adding at a minimum the values for the variables
   `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (see Docker
   [env-file documentation](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)).
3. Pass the path of the file to the make commands using `ENV_FILE`. For example:

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
make deploy-runtimes RUNTIMES='python-X.Y.Z' STACKS='heroku-16 heroku-18'
```

Multiple runtimes can also be specified (useful for when adding a new stack), like so:

```bash
make deploy-runtimes RUNTIMES='python-A.B.C python-X.Y.Z' STACKS='heroku-20'
```

Note: Both `RUNTIMES` and `STACKS` are space delimited.
