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

Enjoy :)
