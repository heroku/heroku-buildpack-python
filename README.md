# Buildpack: Python

This is the official [Scalingo buildpack](https://doc.scalingo.com/buildpacks) for Python apps, powered by [Pipenv](http://docs.pipenv.org/), [pip](https://pip.pypa.io/) and other excellent software.

Recommended web frameworks include **Django** and **Flask**. The recommended webserver is **Gunicorn**. There are no restrictions around what software can be used (as long as it's pip-installable). Web processes must bind to `$PORT`, and only the HTTP protocol is permitted for incoming connections.

Python packages with C dependencies that are not [available on the base image](https://doc.scalingo.com/platform/internals/base-docker-image#top-of-page) are generally not supported, unless `manylinux` wheels are provided by the package maintainers (common).

See it in Action
----------------

Deploying a Python application couldn't be easier:

    $ ls
    Pipfile		Pipfile.lock	Procfile	web.py

    $ scalingo create my-python-app

    $ git push scalingo master
    …
    -----> Python app detected
    -----> Installing python-3.6.6
    -----> Installing pip
    -----> Installing requirements with Pipenv 2018.5.18…
           ...
           Installing dependencies from Pipfile…
    -----> Discovering process types
           Procfile declares types -> (none)

A `Pipfile` or `requirements.txt` must be present at the root of your application's repository.

You can also specify the latest production release of this buildpack for upcoming builds of an existing application:

    $ scalingo env-set BUILDPACK_URL=https://github.com/Scalingo/python-buildpack


Specify a Python Runtime
------------------------

Specific versions of the Python runtime can be specified in your `Pipfile`:

    [requires]
    python_version = "2.7"

Or, more specifically:

    [requires]
    python_full_version = "2.7.15"

Or, with a `runtime.txt` file:

    $ cat runtime.txt
    python-2.7.15

Runtime options include:

- `python-3.7.0`
- `python-3.6.6`
- `python-2.7.15`
