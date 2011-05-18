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