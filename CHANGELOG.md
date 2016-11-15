# Python Buildpack Changelog

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

- Updated setuptools to v8.1.2.
- Updated pip to v23.1.0.

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
