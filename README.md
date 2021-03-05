![python](https://cloud.githubusercontent.com/assets/51578/13712821/b68a42ce-e793-11e5-96b0-d8eb978137ba.png)

# Heroku Buildpack: Python

[![CircleCI](https://circleci.com/gh/heroku/heroku-buildpack-python.svg?style=svg)](https://circleci.com/gh/heroku/heroku-buildpack-python)

This is the official [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for Python apps.

Recommended web frameworks include **Django** and **Flask**, among others. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

See it in Action
----------------
```
$ ls
my-application		requirements.txt	runtime.txt

$ git push heroku main
Counting objects: 4, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (4/4), 276 bytes | 276.00 KiB/s, done.
Total 4 (delta 0), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> Python app detected
remote: -----> Installing python
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

Current default Python Runtime: Python 3.6.12

Alternatively, you can provide a `setup.py` file, or a `Pipfile`.
Using `pipenv` will generate `runtime.txt` at build time if one of the field `python_version` or `python_full_version` is specified in the `requires` section of your `Pipfile`.

Specify a Buildpack Version
---------------------------

You can specify the latest production release of this buildpack for upcoming builds of an existing application:

    $ heroku buildpacks:set heroku/python


Specify a Python Runtime
------------------------

Supported runtime options include:

- `python-3.9.2`
- `python-3.8.8`
- `python-3.7.10`
- `python-3.6.13`
- `python-2.7.18`
