virtualenv
----------

pip
---

Django settings.py
------------------

Sets up a db for every ENV ${NAME}_URL => postgres:// var:

    DATABASES["DATABASE"]
    DATABASES["SHARED_DATABASE"]
    DATABASES["HEROKU_POSTGRESQL_ONYX"]

Aliases DATABASE_URL to default database:

    DATABASES["default"] = DATABASES["DATABASE"]

Injected right after DATABASES = {...}

Hooks
-----

Uses a Makefile for user-controlled hooks into slug compilation.
Target `environment` will be evald in the build script, allowing
custom exports. PIP_OPTS is passed to pip if set.

    environment:
    	export PIP_OPTS=--upgrade
