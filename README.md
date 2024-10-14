![python](https://cloud.githubusercontent.com/assets/51578/13712821/b68a42ce-e793-11e5-96b0-d8eb978137ba.png)

# Heroku Buildpack: Python

[![CI](https://github.com/heroku/heroku-buildpack-python/actions/workflows/ci.yml/badge.svg)](https://github.com/heroku/heroku-buildpack-python/actions/workflows/ci.yml)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for Python apps.

Recommended web frameworks include **Django** and **Flask**, among others. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

## Getting Started

See the [Getting Started on Heroku with Python](https://devcenter.heroku.com/articles/getting-started-with-python) tutorial.

## Application Requirements

A `requirements.txt` or `Pipfile` file must be present in the root (top-level) directory of your app's source code.

## Configuration

### Python Version

We recommend that you specify a Python version for your app rather than relying on the buildpack's default Python version.

For example, to request the latest patch release of Python 3.13, create a `.python-version` file in
the root directory of your app containing:
`3.13`

The buildpack will look for a Python version in the following places (in descending order of precedence):

1. `runtime.txt` file (deprecated)
2. `.python-version` file (recommended)
3. The `python_full_version` field in the `Pipfile.lock` file
4. The `python_version` field in the `Pipfile.lock` file

If none of those are found, the buildpack will use a default Python version for the first
build of an app, and then subsequent builds of that app will be pinned to that version
unless the build cache is cleared or you request a different version.

The current default Python version is: 3.12

The supported Python versions are:

- Python 3.13
- Python 3.12
- Python 3.11
- Python 3.10

These Python versions are deprecated on Heroku:

- Python 3.9
- Python 3.8 (only available on the [Heroku-20](https://devcenter.heroku.com/articles/heroku-20-stack) stack)

Python versions older than those listed above are no longer supported, since they have reached
end-of-life [upstream](https://devguide.python.org/versions/#supported-versions).

## Documentation

For more information about using Python on Heroku, see [Dev Center](https://devcenter.heroku.com/categories/python-support).
