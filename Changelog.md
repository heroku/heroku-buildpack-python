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
