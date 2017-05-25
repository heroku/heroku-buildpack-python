# Python Buildpack Binaries

For Cedar-14 stack
------------------

To get started with it, create an app on Heroku inside a clone of this repository, and set your S3 config vars:

    $ heroku create --buildpack https://github.com/heroku/heroku-buildpack-python#not-heroku
    $ heroku config:set WORKSPACE_DIR=builds
    $ heroku config:set AWS_ACCESS_KEY_ID=<your_aws_key>
    $ heroku config:set AWS_SECRET_ACCESS_KEY=<your_aws_secret>
    $ heroku config:set S3_BUCKET=<your_s3_bucket_name>


Then, shell into an instance and run a build by giving the name of the formula inside `builds`:

    $ heroku run bash
    Running `bash` attached to terminal... up, run.6880
    ~ $ bob build runtimes/python-2.7.6

    Fetching dependencies... found 2:
      - libraries/sqlite

    Building formula runtimes/python-2.7.6:
        === Building Python 2.7.6
        Fetching Python v2.7.6 source...
        Compiling...

If this works, run `bob deploy` instead of `bob build` to have the result uploaded to S3 for you.

To speed things up drastically, it'll usually be a good idea to `heroku run bash --size PX` instead.

For Heroku-16 stack
-------------------

1. Ensure GNU Make and Docker are installed.
2. From the root of the buildpack repository, run: `make buildenv-heroku-16`
3. Follow the instructions displayed!


Enjoy :)
