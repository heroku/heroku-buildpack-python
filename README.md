![python](https://cloud.githubusercontent.com/assets/51578/13712821/b68a42ce-e793-11e5-96b0-d8eb978137ba.png)

# Heroku Buildpack: Python

[![Build Status](https://travis-ci.org/heroku/heroku-buildpack-python.svg?branch=master)](https://travis-ci.org/heroku/heroku-buildpack-python)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for Python apps.

Recommended web frameworks include **Django** and **Flask**, among others. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

Python packages with C dependencies that are not [available on the stack image](https://devcenter.heroku.com/articles/stack-packages) are generally not supported, unless `manylinux` wheels are provided by the package maintainers (common). For recommended solutions, check out [this article](https://devcenter.heroku.com/articles/python-c-deps) for more information.

See it in Action
----------------
```
$ ls
my-application		requirements.txt	runtime.txt

$ git push heroku master
Counting objects: 4, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (4/4), 276 bytes | 276.00 KiB/s, done.
Total 4 (delta 0), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> Python app detected
remote: -----> Installing python-3.7.4
remote: -----> Installing pip
remote: -----> Installing SQLite3
remote: -----> Installing requirements with pip
remote:        Collecting flask (from -r /tmp/build_c2c067ef79ff14c9bf1aed6796f9ed1f/requirements.txt (line 1))
remote:          Downloading ...
remote:        Installing collected packages: Werkzeug, click, MarkupSafe, Jinja2, itsdangerous, flask
remote:        Successfully installed Jinja2-2.10 MarkupSafe-1.1.0 Werkzeug-0.14.1 click-7.0 flask-1.0.2 itsdangerous-1.1.0
remote:
remote: -----> Discovering process types
remote:        Procfile declares types -> (none)
remote:
```

A `requirements.txt` must be present at the root of your application's repository to deploy.

To specify your python version, you also need a `runtime.txt` file - unless you are using the default Python runtime version.

Current default Python Runtime: Python 3.6.9

Alternatively, you can provide a `setup.py` file, or a `Pipfile`. Using `Pipenv` will generate `runtime.txt` based on `python-version` at build time.

Specify a Buildpack Version
---------------------------

You can specify the latest production release of this buildpack for upcoming builds of an existing application:

    $ heroku buildpacks:set heroku/python


Specify a Python Runtime
------------------------

Supported runtime options include:

- `python-3.7.4`
- `python-3.6.9`
- `python-2.7.16`

## Tests

The buildpack tests use [Docker](https://www.docker.com/) to simulate
Heroku's [stack images.](https://devcenter.heroku.com/articles/stack)

To run the test suite:

```
make test
```

Or to test in a particular stack:

```
make test-heroku-18
make test-heroku-16
```

The tests are run via the vendored
[shunit2](https://github.com/kward/shunit2)
test framework.
