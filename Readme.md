Python Build Pack
====================
The Python Build Pack (PBP) is a build pack for running Python and Django
apps on Heroku.

## Usage

If `requirements.txt` is present, the PBP considers the directory a Python app
with packages to install via pip.

Furthermore, if `${PROJECT}/settings.py` is present, the PBP considers the
directory a Python/Django app, and patches `settings.py` to parse the Heroku
DATABASE_URL config vars. It then sets default process types to use the Django
web server.


## Hacking

To change this buildpack, fork it on GitHub. Push up changes to your
fork, then create a test app with `--buildpack YOUR_GITHUB_URL` and
push to it. If you already have an existing app you may use
`heroku config add BUILDPACK_URL=YOUR_GITHUB_URL` instead.

For example, you could adapt it to use pypy at build time.... to be continued

