Python Language Pack
====================
The Python Language Pack (PLP) is a language pack for running Python and Django
apps on Heroku.

If `requirements.txt` is present, the PLP considers the directory a Python app
with packages to install via pip.

Furthermore, if `${project}/settings.py` is present, the PLP considers the
directory a Python/Django app, and patches `settings.py` to parse the Heroku
DATABASE_URL config vars. It then sets default process types to use the Django
web server and console.

Compile Hooks
-------------
The PLP uses a Makefile for user-controlled hooks into slug compilation. If
present, the `make environment` rule will be eval'd in the compile script, allowing
user-defined exports.

A sample Makefile to force a re-build of every pip package is:

    environment:
    	export PIP_OPTS=--upgrade

(<a href="https://github.com/heroku/language-pack-python/raw/master/test/canary_django/Makefile">raw file</a>)

Django settings.py
------------------
The PLP injects code into settings.py to alias every Heroku database URL
config var. Every variable of the format ${NAME}_URL => postgres:// will be
added to the settings.DATABASES hash.

On an app with both a shared SHARED_DATABASE_URL and a dedicated
HEROKU_POSTGRESQL_RED_URL that is promoted to DATABASE_URL, settings will look
like:

    {
      'DATABASE':               {'ENGINE': 'psycopg2', 'NAME': 'dedicated', ...},
      'HEROKU_POSTGRESQL_RED':  {'ENGINE': 'psycopg2', 'NAME': 'dedicated', ...},
      'SHARED':                 {'ENGINE': 'psycopg2', 'NAME': 'shared', ...},
      'default':                {'ENGINE': 'psycopg2', 'NAME': 'dedicated', ...},
    }

These aliases can be referenced and further modified at the end of the settings file.
