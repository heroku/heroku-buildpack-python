# Scalingo python buildpack

A [buildpack](http://doc.scalingo.com/buildpacks/) for Python based apps.

It handles Python 2.x apps as well as Python 3.x apps.

## Usage

This buildpack will be used if there is a `requirements.txt` or `setup.py` file in the root directory of your project.

```
    $ git push scalingo master
    ...
    -----> Python app detected
    -----> Installing runtime (python-2.7.10)
    -----> Installing dependencies using pip
           Downloading/unpacking requests (from -r requirements.txt (line 1))
           Installing collected packages: requests
           Successfully installed requests
           Cleaning up...
    -----> Discovering process types
           Procfile declares types -> (none)
```

## Cached dependencies

The buildpack has a script `bin/deploy` which uses the `buildpack-deployer`
project to cache system dependencies instead of downloading them all from the
Internet at each deployment.

Using cached system dependencies is accomplished by overriding curl during
staging. See [bin/compile](bin/compile#L71-75)

## Run the tests

There are [Machete](https://github.com/pivotal-cf-experimental/machete) based integration tests available in [cf_spec](cf_spec).

The test script is included in machete and can be run as follows:

```bash
BUNDLE_GEMFILE=cf.Gemfile bundle install
git submodule update --init
`BUNDLE_GEMFILE=cf.Gemfile bundle show machete`/scripts/buildpack-build [mode]
```

## Contributing

1. Fork the project
1. Submit a pull request

## Specify a Runtime

You can also provide arbitrary releases Python with a `runtime.txt` file.

```
$ cat runtime.txt
python-3.5.0
```

- python-2.7.10
- python-3.5.0
- pypy-2.6.1 (unsupported, experimental)
- pypy3-2.4.0 (unsupported, experimental)

Other [unsupported runtimes](https://github.com/Scalingo/python-buildpack/tree/master/builds/runtimes) are available as well.
