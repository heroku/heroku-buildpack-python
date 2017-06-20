![python](https://cloud.githubusercontent.com/assets/51578/13712821/b68a42ce-e793-11e5-96b0-d8eb978137ba.png)

# Heroku Buildpack: Python

[![Build Status](https://travis-ci.org/heroku/heroku-buildpack-python.svg?branch=master)](https://travis-ci.org/heroku/heroku-buildpack-python)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for Python apps, powered by [pip](https://pip.pypa.io/) and other excellent software.

Recommended web frameworks include **Django** and **Flask**. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

Some Python packages with obscure C dependencies (e.g. scipy) are [not compatible](https://devcenter.heroku.com/articles/python-c-deps).

See it in Action
----------------

Deploying a Python application couldn't be easier:

    $ ls
    Procfile  requirements.txt  web.py

    $ heroku create --buildpack heroku/python

    $ git push heroku master
    ...
    -----> Python app detected
    -----> Installing python-3.6.1
         $ pip install -r requirements.txt
           Collecting requests (from -r requirements.txt (line 1))
             Downloading requests-2.12.4-py2.py3-none-any.whl (576KB)
           Installing collected packages: requests
           Successfully installed requests-2.12.4

    -----> Discovering process types
           Procfile declares types -> (none)

A `requirements.txt` file must be present at the root of your application's repository.

You can also specify the latest production release of this buildpack for upcoming builds of an existing application:

    $ heroku buildpacks:set heroku/python


Specify a Python Runtime
------------------------

Specific versions of the Python runtime can be specified with a `runtime.txt` file:

    $ cat runtime.txt
    python-2.7.13

Runtime options include:

- `python-3.6.1`
- `python-2.7.13`
- `pypy-5.7.1` (unsupported, experimental)
- `pypy3-5.5.1` (unsupported, experimental)
