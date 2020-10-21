# Python Buildpack Changelog

## Unreleased


## v184 (2020-10-21)

- Vendor buildpack-stdlib instead of fetching from S3 (#1100).
- Fix metric names for metrics emitted within `sub_env` (#1099).

## v183 (2020-10-12)

- Add support for Heroku-20 (#968).

## v182 (2020-10-06)

- Python 3.9.0 is now available (CPython) (#1090).
- Migrate from the `lang-python` S3 bucket to `heroku-buildpack-python` (#1089).
- Remove `vendor/shunit2` (#1086).
- Replace `BUILDPACK_VENDOR_URL` and `USE_STAGING_BINARIES` with `BUILDPACK_S3_BASE_URL` (#1085).

## v181 (2020-09-29)

- PyPy 2.7 and 3.6, version 7.3.2 are now available (Note: PyPy support is in beta) (#1081).

## v180 (2020-09-24)

- Python 3.8.6 is now available (CPython) (#1072).

## v179 (2020-09-23)

- Remove duplicate pipenv metric event (#1070).
- Emit metrics for how the Python version was chosen for an app (#1069).
- Emit Python version metric events for all builds, not just clean installs (#1066).

## v178 (2020-09-07)

- Python 3.5.10 is now available (CPython) (#1062).

## v177 (2020-08-18)

- Python 3.6.12 and 3.7.9 are now available (CPython) (#1054).
- The default Python version for new apps is now 3.6.12 (previously 3.6.11) (#1054).

## v176 (2020-08-12)

- Rebuild the Python 3.4.10 archives with the correct version of Python (#1048).
- Fix the security update version check message for apps using PyPy (#1040).
- Remove `vendor/test-utils` (#1043).

## v175 (2020-08-05)

- Update pip from 20.0.2 to 20.1.1 for Python 2.7 and Python 3.5+ (#1030).
- Update setuptools from 39.0.1 to: (#1024)
  - 44.1.1 for Python 2.7
  - 43.0.0 for Python 3.4
  - 47.1.1 for Python 3.5+
- Switch the `heroku-buildpack-python` repository default branch from `master` to `main` (#1029).

## v174 (2020-07-30)

- For repeat builds, also manage the installed versions of setuptools/wheel, rather than just that of pip (#1007).
- Install an explicit version of wheel rather than the latest release at the time (#1007).
- Output the installed version of pip, setuptools and wheel in the build log (#1007).
- Errors installing pip/setuptools/wheel are now displayed in the build output and fail the build early (#1007).
- Install pip using itself rather than `get-pip.py` (#1007).
- Disable pip's version check + cache when installing pip/setuptools/wheel (#1007).
- Install setuptools from PyPI rather than a vendored copy (#1007).
- Reduce the number of environment variables exposed to `bin/{pre,post}_compile` and other subprocesses (#1011).

## v173 (2020-07-21)

- Python 3.8.5 is now available (CPython).

## v172 (2020-07-17)

- Python 3.8.4 is now available (CPython).

## v171 (2020-07-07)

- Python 3.6.11 and 3.7.8 are now available (CPython).

## v170 (2020-05-19)

- Python 2.7.18, 3.5.9, 3.7.7 and 3.8.3 are now available (CPython).
- PyPy 2.7 and 3.6, version 7.3.1 are now available (Note: PyPy support is in beta).
- Docs: Fix explanation of runtime.txt generation when using pipenv.
- Bugfix: Correctly detect Python version when using a `python_version` of `3.8` in `Pipfile.lock`.

## v169 (2020-04-22)

- Add a Hatchet test for python 3.8.2
- Set Code Owners to @heroku/langauges
- Bugfix: Caching on subsequent redeploys
- Update tests to support latest version of Python

## v168 (2020-04-06)

- Doc: Update Readme with version numbers
- update Code Owners to include the Heroku Buildpack Maintainers team
- Deprecation warning: `BUILD_WITH_GEO_LIBRARIES` is now deprecated. See warning for details.
- Clean up build log output
- Update Python versions in README to match docs
- Django version detection fixed, link updated

## v167 (2020-03-26)

- Add failcase for cache busting
- Bugfix: Clearing pip dependencies

## v166 (2020-03-05)

- Correct ftp to https in vendored file
- Warn for Django 1.11 approaching EOL, provide link to roadmap

## v165 (2020-02-27)

- Python 3.8.2 now available.

## v164 (2020-02-20)

- Update requirements.txt builds to use Pip 20.0.2
- Download get-pip.py to tmpdir instead of root dir

## v163 (2019-12-23)

- New pythons released:
  Python 3.8.1, 3.7.6, 3.6.10 (CPython)
  Beta Release: Pypy 2.7 and 3.6, version 7.2.0

## v162 (2019-12-06)

- Bug fix: fragile sqlite3 install

## v161 (2019-12-2)

- Bug fix: Sqlite3 version bump

## v160 (2019-10-23)

- Bugfix: Pipenv no longer installs twice in CI

## v159 (2019-10-22)

- Python 2.7.17 now available on Heroku 18 and 16.

## v158 (2019-10-21)

- Python 3.7.5 and 3.8.0 now available on Heroku 18 and 16.
- Add support for Python 3.8 branch
- Sqlite3 Update:
  - Test Improvements
- Add support for staging binary testing

## v157 (2019-09-18)

- Typo fixes

## v156 (2019-09-12)

- Python 3.6.9 and 3.7.4 now available.

- Move get-pip utility to S3
- Build utility and documentation updates
- Bump Hatchet tests to point at new default python version.

## v155 (2019-08-22)

add docs and make target for heroku-18 bob builds

## v154 (2019-07-17)

Fix python 3.5.7 formula actually building 3.7.2

## v153 (2019-06-21)

Hotfix for broken heroku-16 deploys

## v152 (2019-04-04)

Python 3.7.3 now available.

## v151 (2019-03-21)

Python 3.5.7 and 3.4.10 now available on all Heroku stacks.

## v150 (2019-03-13)

Python 2.7.16 now available on all Heroku stacks.

## v149 (2019-03-04)

Hotfix for broken Cedar 14 deploys

## v148 (2019-02-21)

No user facing changes, improving internal metrics

## v147 (2019-02-07)

Python 3.7.2 and 3.6.8 now available on all Heroku stacks.

## v146 (2018-11-11)

Python 3.7.1, 3.6.7, 3.5.6 and 3.4.9 now available on all Heroku stacks.

## v145 (2018-11-08)

Testing and tooling expanded to better support new runtimes

## v144 (2018-10-10)

Switch to cautious upgrade for Pipenv install to ensure the pinned pip version
is used with Pipenv

## v143 (2018-10-09)

Add support for detecting `SLUGIFY_USES_TEXT_UNIDECODE`, which is required to
install Apache Airflow version 1.10 or higher.

## v142 (2018-10-08)

Improvements to Python install messaging

## v139, 140, 141

No user-facing changes, documenting for version clarity

## v138 (2018-08-01)

Use stack image SQLite3 instead of vendoring

## v137 (2018-07-17)

Prevent 3.7.0 from appearing as unsupported in buildpack messaging.

## v136 (2018-06-28)

Upgrade to 3.6.6 and support 3.7.0 on all runtimes.

## v135 (2018-05-29)

Upgrade Pipenv to v2018.5.18.

## v134 (2018-05-02)

Default to 3.6.5, bugfixes.

## v133

Fixes for Pip 10 release.

## v132

Improve pip installation, with the release of v9.0.2.

## v131

Fix bug with pip.

## v130

Better upgrade strategy for pip.

## v129

Don't upgrade pip (from v128).

## v128

Upgrade pip, pin to Pipenv v11.8.2.

## v127

Pin to Pipenv v11.7.1.

## v126

Bugfixes.

## v125

Bugfixes.

## v124

Update buildpack to automatically install `[dev-packages]` during Heroku CI Pipenv builds.

- Skip installs if Pipfile.lock hasn't changed, and uninstall stale dependencies with Pipenv.
- Set `PYTHONPATH` during collectstatic runs.
- No longer warn if there is no `Procfile`.
- Update Pipenv's "3.6" runtime specifier to point to "3.6.4".

## v123

Update gunicorn `init.d` script to allow overrides.

## v122

Update default Python to v3.6.4.

## v121

Update default Python to v3.6.3.

## v120

Use `$ pipenv --deploy`.

## v119

Improvements to Pipenv support, warning on unsupported Python versions.

- We now warn when a user is not using latest 2.x or 3.x Python.
- Heroku now supports `[requires]` `python_full_version` in addition to `python_version`.

## v118

Improvements to Pipenv support.

## v117

Bug fix.

## v116

Vendoring improvements.

- Geos libraries should work on Heroku-16 now.
- The libffi/libmemcached vendoring step is now skipped on Heroku-16 (since they are installed in the base image).

## v115

Revert a pull request.

- No longer using `sub_env` for `pip install` step.

## v114

- Bugfixes.

Blacklisting `PYTHONHOME` and `PYTHONPATH` for older apps. Upgrades to nltk support.

## v113

Updates to Pipenv support.

## v112

Bugfix.

- Fixed grep output bug.

## v111

Linting, bugfixes.

## v110

Update default Python to 3.6.2.

## v109

Update Default Python to 3.6.1, bugfixes.

- Fixed automatic pip uninstall of dependencies removed from requirements.txt.

## v108

Fix output for collectstatic step.

## v107

Bugfix for C dependency installation.

## v106

Don't install packages that could mess up packaging.

 - The Python buildpack will automatically remove `six`, `pyparsing`, `appdirs`,
   `setuptools`, and `distribute` from a `requirements.txt` file now, as these
   packages are provided by the Python buildpack.

## v105

Improvements to output messaging.

## v104

General improvements.

- Fix for Heroku CI.
- Use `pkg_resources` to check if a distribution is installed instead of
  parsing `requirements.txt`. ([#395][395])

[395]: https://github.com/heroku/heroku-buildpack-python/pull/395

## v103

Bug fixes and improvements.

- Fix for Pipenv.
- Fix for Heroku CI.
- Improve handling of `WEB_CONCURRENCY` when using multiple buildpacks.
- Adjust environment variables set during the build to more closely match those in the dyno environment (`DYNO` is now available, `STACK` is not).
- Restore the build cache prior to running bin/pre_compile.

## v102

Buildpack code cleanup.

- Improved messaging around NLTK.

## v101

Updated setuptools installation method.

- Improved pipenv support.

## v100

Preliminary pipenv support.

## v99

Cleanup.

## v98

Official NLTK support and other improvements.

- Support for `nltk.txt` file for declaring corpora to be downloaded.
- Leading zeros for auto-set `WEB_CONCURRENCY`.

## v97

Improved egg-link functionality.

## v96

Bugfix.

## v95

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

- Python 2.7.13 uses UCS-4 build, more compatible with linux wheels.
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

Update to library detection mechanisms (pip-pop).

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

Fixed `.heroku/venv` error with modern apps.

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
