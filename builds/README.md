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

Then, shell into an instance and run a build by giving the name of the formula inside `builds`:

    $ scalingo run bash
    ~ $ bob build runtimes/python-2.7.6

    Fetching dependencies... found 2:
      - libraries/sqlite

    Building formula runtimes/python-2.7.6:
        === Building Python 2.7.6
        Fetching Python v2.7.6 source...
        Compiling...

If this works, run `bob deploy` instead of `bob build` to have the result uploaded to S3 for you.

To speed things up drastically, it'll usually be a good idea to `scalingo run bash --size 2XL` instead.

For Heroku-16 stack
-------------------

1. Ensure GNU Make and Docker are installed.
2. From the root of the buildpack repository, run: `make buildenv-heroku-16`
3. Follow the instructions displayed!

Enjoy :)
