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

You can e.g. `bash` into each of the images you built using their tag:

    $ scalingo run bash
    ~ $ bob build runtimes/python-2.7.6

You then have a shell where you can run `bob build`, `bob deploy`, and so forth. You can of course also invoke these programs directly with `docker run`:

    docker run --rm -ti heroku-python-build-heroku-18 bob build runtimes/python-2.7.15

In order to `bob deploy`, AWS credentials must be set up, as well as name and prefix of your custom S3 bucket (unless you're deploying to the Heroku production buckets that are pre-defined in each `Dockerfile`); see next section for details.

To speed things up drastically, it'll usually be a good idea to `scalingo run bash --size 2XL` instead.

File `dockerenv.default` contains a list of required env vars; most of these have default values defined in `Dockerfile`. You can copy this file to a location outside the buildpack and modify it with the values you desire and pass its location with `--env-file`, or pass the env vars to `docker run` using `--env`.

Out of the box, each `Dockerfile` has the correct values predefined for `S3_BUCKET`, `S3_PREFIX`, and `S3_REGION`. If you're building your own packages, you'll likely want to change `S3_BUCKET` and `S3_PREFIX` to match your info. Instead of setting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` into that file, you may also pass them to `docker run` through the environment, or explicitly using `--env`, in order to prevent accidental commits of credentials.

Enjoy :)
