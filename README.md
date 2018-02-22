![python](https://cloud.githubusercontent.com/assets/51578/13712821/b68a42ce-e793-11e5-96b0-d8eb978137ba.png)

# Heroku Buildpack: Python

[![Build Status](https://travis-ci.org/heroku/heroku-buildpack-python.svg?branch=master)](https://travis-ci.org/heroku/heroku-buildpack-python)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for Python apps, powered by [Pipenv](http://docs.pipenv.org/), [pip](https://pip.pypa.io/) and other excellent software.

Recommended web frameworks include **Django** and **Flask**. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

Some Python packages with obscure C dependencies are [not compatible](https://devcenter.heroku.com/articles/python-c-deps).

See it in Action
----------------

Deploying a Python application couldn't be easier:

    $ ls
    Pipfile		Procfile	web.py

    $ heroku create --buildpack heroku/python

    $ git push heroku master
    …
    -----> Python app detected
    -----> Installing python-3.6.4
    -----> Installing pip
    -----> Installing requirements with latest pipenv…
           ...
           Installing dependencies from Pipfile…
    -----> Discovering process types
           Procfile declares types -> (none)

A `Pipfile` or `requirements.txt` must be present at the root of your application's repository.

You can also specify the latest production release of this buildpack for upcoming builds of an existing application:

    $ heroku buildpacks:set heroku/python


Specify a Python Runtime
------------------------

Specific versions of the Python runtime can be specified with a `runtime.txt` file:

    $ cat runtime.txt
    python-2.7.14

Or, with a `Pipfile.lock` (generated from the following `Pipfile`):

    [requires]
    python_version = "2.7"

Or, more specifically:

    [requires]
    python_full_version = "2.7.14"

Runtime options include:

- `python-3.6.4`
- `python-2.7.14`
- `pypy-5.7.1` (unsupported, experimental)
- `pypy3-5.5.1` (unsupported, experimental)
