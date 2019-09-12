# Python Buildpack Changelog

# Master

--------------------------------------------------------------------------------

# 156 (2019-09-12)

- Python 3.6.9 and 3.7.4 now available.

- Move get-pip utility to S3
- Build utility and documentation updates
- Bump Hatchet tests to point at new default python version.

# 155 (2019-08-22)

add docs and make target for heroku-18 bob builds

# 154 (2019-07-17)

Fix python 3.5.7 formula actually building 3.7.2

# 153 (2019-06-21)

Hotfix for broken heroku-16 deploys

# 152 (2019-04-04)

Python 3.7.3 now available.

# 151 (2019-03-21)

Python 3.5.7 and 3.4.10 now available on all Heroku stacks.

# 150 (2019-03-13)

Python 2.7.16 now available on all Heroku stacks.

# 149 (2019-03-04)

Hotfix for broken Cedar 14 deploys

# 148 (2019-02-21)

No user facing changes, improving internal metrics

# 147 (2019-02-07)

Python 3.7.2 and 3.6.8 now available on all Heroku stacks.

# 146 (2018-11-11)

Python 3.7.1, 3.6.7, 3.5.6 and 3.4.9 now available on all Heroku stacks.

# 145 (2018-11-08)

Testing and tooling expanded to better support new runtimes

# 144 (2018-10-10)

Switch to cautious upgrade for Pipenv install to ensure the pinned pip version
is used with Pipenv

# 143 (2018-10-09)

Add support for detecting SLUGIFY_USES_TEXT_UNIDECODE, which is required to
install Apache Airflow version 1.10 or higher.

# 142 (2018-10-08)

Improvements to Python install messaging

# 139, 140, 141

No user-facing changes, documenting for version clarity

# 138 (2018-08-01)

Use stack image SQLite3 instead of vendoring

# 137 (2018-07-17)

Prevent 3.7.0 from appearing as unsupported in buildpack messaging.

# 136 (2018-06-28)

Upgrade to 3.6.6 and support 3.7.0 on all runtimes.

# 135 (2018-05-29)

Upgrade Pipenv to v2018.5.18.

# 134 (2018-05-02)

Default to 3.6.5, bugfixes.

# 133

Fixes for Pip 10 release.

# 132

Improve pip installation, with the release of v9.0.2.

# 131

Fix bug with pip.

# 130

Better upgrade strategy for pip.

# 129

Don't upgrade pip (from v128).

# 128

Upgrade pip, pin to Pipenv v11.8.2.

# 127

Pin to Pipenv v11.7.1.

# 126

Bugfixes.

# 125

Bugfixes.

# 124

Update buildpack to automatically install `[dev-packages]` during Heroku CI Pipenv builds.

- Skip installs if Pipfile.lock hasn't changed, and uninstall stale dependencies with Pipenv.
- Set `PYTHONPATH` during collectstatic runs.
- No longer warn if there is no `Procfile`.
- Update Pipenv's "3.6" runtime specifier to point to "3.6.4".

# 123

Update gunicorn `init.d` script to allow overrides.

# 122

Update default Python to v3.6.4.

# 121

Update default Python to v3.6.3.

# 120

Use `$ pipenv --deploy`.

# 119

Improvements to Pipenv support, warning on unsupported Python versions.

- We now warn when a user is not using latest 2.x or 3.x Python.
- Heroku now supports `[requires]` `python_full_version` in addition to `python_version`.

# 118

Improvements to Pipenv support.

# 117

Bug fix.

# 116

Vendoring improvements.

- Geos libraries should work on Heroku-16 now.
- The libffi/libmemcached vendoring step is now skipped on Heroku-16 (since they are installed in the base image).

# 115

Revert a pull request.

- No longer using `sub_env` for `pip install` step.

# 114

- Bugfixes.

Blacklisting `PYTHONHOME` and `PYTHONPATH` for older apps. Upgrades to nltk support.

# 113

Updates to Pipenv support.

# 112

Bugfix.

- Fixed grep output bug.

# 111

Linting, bugfixes.

# 110

Update default Python to 3.6.2.

# 109

Update Default Python to 3.6.1, bugfixes.

- Fixed automatic pip uninstall of dependencies removed from requirements.txt.

# 108

Fix output for collectstatic step.

# 107

Bugfix for C dependency installation.

# 106

 Don't install packages that could mess up packaging.

 - The Python buildpack will automatically remove `six`, `pyparsing`, `appdirs`,
   `setuptools`, and `distribute` from a `requirements.txt` file now, as these
   packages are provided by the Python buildpack.

 # 105

 Improvements to output messaging.

# 104

General improvements.

- Fix for Heroku CI.
- Use `pkg_resources` to check if a distribution is installed instead of
  parsing `requirements.txt`. ([#395][395])

[395]: https://github.com/heroku/heroku-buildpack-python/pull/395

## 103

Bug fixes and improvements.

- Fix for Pipenv.
- Fix for Heroku CI.
- Improve handling of WEB_CONCURRENCY when using multiple buildpacks.
- Adjust environment variables set during the build to more closely match those in the dyno environment (DYNO is now available, STACK is not).
- Restore the build cache prior to running bin/pre_compile.

## 102

Buildpack code cleanup.

- Improved messaging around NLTK.

## 101

Updated setuptools installation method.

- Improved pipenv support.

## 100

Preliminary pipenv support.

## 99

Cleanup.

## 98

Official NLTK support and other improvements.

- Support for `nltk.txt` file for declaring corpora to be downloaded.
- Leading zeros for auto-set WEB_CONCURRENCY.

## 97

Improved egg-link functionality.

## 96

Bugfix.

## 95

Improved output support.

## v94

Improved support for PyPy.

## v93

Improved support for PyPy.

## v92

Improved cache functionality and fix egg-links regression.

## v91

Bugfix, rolled back to v88.

## v90

Bugfix.

## v89

Improved cache functionality and fix egg-links regression.

## v88

Fixed bug with editable pip installations.

## v87

Updated default Python 2.7.13.

- Python 2.7.13 uses UCS-4 build, more compatibile with linux wheels.
- Updated setuptools to v32.1.0.

## v86

Refactor and multi-buildpack compatibility.

## v85

Packaging fix.

## v84

Updated pip and setuptools.

- Updated pip to v9.0.1.
- Updated setuptools to v28.8.0.

## v83

Support for Heroku CI.

- Cffi support for argon2

## v82 (2016-08-22)

Update to library detection mechnisms (pip-pop).

- Updated setuptools to v25.5.0

## v81 (2016-06-28)

Updated default Python to 2.7.11.

- Updated pip to v8.1.2.
- Updated setuptools to v23.1.0.

## v80 (2016-04-05)

Improved pip-pop compatibility with latest pip releases.

## v79 (2016-03-22)

Compatibility improvements with heroku-apt-buildpack.

## v78 (2016-03-18)

Added automatic configuration of Gunicorn's `FORWARDED_ALLOW_IPS` setting.

Improved detection of libffi dependency when using bcrypt via `Django[bcrypt]`.

Improved GDAL support.

- GDAL dependency detection now checks for pygdal and is case-insensitive.
- The vendored GDAL library has been updated to 1.11.1.
- GDAL bootstrapping now also installs the GEOS and Proj.4 libraries.

Updated pip to 8.1.1 and setuptools to 20.3.

## v77 (2016-02-10)

Improvements to warnings and minor bugfix.

## v76 (2016-02-08)

Improved Django collectstatic support.

- `$ python manage.py collectstatic` will only be run if `Django` is present in `requirements.txt`.
- If collectstatic fails, the build fails. Full traceback is provided.
- `$DISABLE_COLLECTSTATIC`: skip collectstatic step completely (not new).
- `$DEBUG_COLLECTSTATIC`: echo environment variables upon collectstatic failure.
- Updated build output style.
- New warning for outdated Python (via pip `InsecurePlatform` warning).

## v75 (2016-01-29)

Updated pip and Setuptools.

## v74 (2015-12-29)

Added warnings for lack of Procfile.

## v72 (2015-12-07)

Updated default Python to 2.7.11.

## v72 (2015-12-03)

Added friendly warnings for common build failures.

## v70 (2015-10-29)

Improved compatibility with multi and node.js buildpacks.

## v69 (2015-10-12)

Revert to v66.

## v68 (2015-10-12)

Fixed .heroku/venv error with modern apps.

## v67 (2015-10-12)

Further improved cache compatibility with multi and node.js buildpacks.

## v66 (2015-10-09)

Improved compatibility with multi and node.js buildpacks.

## v65 (2015-10-08)

Reverted v64.

## v64 (2015-10-08)

Improved compatibility with multi and node.js buildpacks.

## v63 (2015-10-08)

Updated Pip and Setuptools.

- Setuptools updated to v18.3.2
- Pip updated to v7.1.2


## v62 (2015-08-07)

Updated Pip and Setuptools.

- Setuptools updated to v18.1
- Pip updated to v7.1.0

## v61 (2015-06-30)

Updated Pip and Setuptools.

- Setuptools updated to v18.0.1
- Pip updated to v7.0.3

## v60 (2015-05-27)

Default Python is now latest 2.7.10. Updated Pip and Distribute.

- Default Python version is v2.7.10
- Setuptools updated to v16.0
- Pip updated to v7.0.1
