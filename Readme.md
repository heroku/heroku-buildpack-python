# Scalingo python buildpack

A [buildpack](http://docs.cloudfoundry.org/buildpacks/) for Python based apps.

It handles Python 2.x apps as well as Python 3.x apps.

This is based on the [Heroku buildpack] (https://github.com/heroku/heroku-buildpack-python).

## Usage

This buildpack will be used if there is a `requirements.txt` or `setup.py` file in the root directory of your project.

```
    $ git push scalingo master
    ...
    -----> Python app detected
    -----> Installing runtime (python-2.7.9)
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

## Contributing

### Run the tests

There are [Machete](https://github.com/pivotal-cf-experimental/machete) based integration tests available in [cf_spec](cf_spec).

The test script is included in machete and can be run as follows:

```bash
BUNDLE_GEMFILE=cf.Gemfile bundle install
git submodule update --init
`BUNDLE_GEMFILE=cf.Gemfile bundle show machete`/scripts/buildpack-build [mode]
```

### Pull Requests

1. Fork the project
1. Submit a pull request

## Reporting Issues

Open an issue on this project

## Active Development

The project backlog is on [Pivotal Tracker](https://www.pivotaltracker.com/projects/1042066)
