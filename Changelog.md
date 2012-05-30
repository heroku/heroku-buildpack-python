## v7

Features:

* Full removal of Django setting injection for new apps.
* Automatic execution of collectstatic.
* Suppress collectstatic errors via env SILENCE_COLLECTSTATIC.
* Increase settings.py search depth to 3.
* Search recursively from included requirements.txt files.


## v6 (03/23/2012)

Features:

* Dist packages (setup.py) support.
* Move new virtualenvs to `/app/.heroku/venv`.
* Heavily improved Django app detection, accounting for `Django` in `requirements.txt`.
* Literate [documentation](http://python-buildpack.herokuapp.com).
* Default `$PYTHONHOME`, `$PYTHONPATH`, and `$LANG` configurations.
* Disable Django setting injection with `$DISABLE_INJECTION` + [user_env_compile](http://devcenter.heroku.com/articles/labs-user-env-compile).
* General code refactor and improved messaging.
* Unit tests.

Bugfixes:

* Django 1.4 startproject template layout support.
* Django `manage.py` location can now be independent from `settings.py`.

## v5 (02/01/2012)

Bugfixes:

* Git requirements 100% work.


## v4 (01/20/2012)

Features:

* Updated to virtualenv v1.7 with patched pip v1.2.
* Actually activate created virtualenv within compile process.
* Use distribute instead of deprecated setuptools.
* Automatically destroy and rebuild corrupt virtualenvs.
* Refactor django and pylibmc detection.

Bugfixes:

* Fixed `package==dev` in requirements with patched pip embedded within virtualenv. Patch upstreamed.
* Minor curl/rm flag fixes (thanks, contributors!)


## v3 (12/07/2011)

Bugfixes:

* Better django setup.py injection.


## v2 (11/15/2011)

Features:

* Support for pylibmc and libmemcached +sasl.

Bugfixes:

* Detect when virtualenv is checked in and alert user.


## v1 (10/01/2011)

* Conception.
