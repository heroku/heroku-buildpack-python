Python Build Pack
====================
The Python Build Pack (PBP) is a build pack for running Python and Django
apps on Heroku.

If `requirements.txt` is present, the PBP considers the directory a Python app
with packages to install via pip.

Furthermore, if `${PROJECT}/settings.py` is present, the PBP considers the
directory a Python/Django app, and patches `settings.py` to parse the Heroku
DATABASE_URL config vars. It then sets default process types to use the Django
web server.

External Build Pack
----------------------
Cutting-edge development is taking place in this repo. To use this on Heroku,
set a `BUILDPACK_URL` config var with a fully authenticated URL to this repo:

    $ heroku config:add BUILDPACK_URL=https://nzoschke:XXXXXXX@github.com/heroku/heroku-buildpack-python.git

On next push, slug-compiler will use this BP instead of the built-in one.