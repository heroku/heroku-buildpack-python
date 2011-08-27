Python Language Pack
====================
The Python Language Pack (PLP) is a language pack for running Python and Django
apps on Heroku.

If `requirements.txt` is present, the PLP considers the directory a Python app
with packages to install via pip.

Furthermore, if `${PROJECT}/settings.py` is present, the PLP considers the
directory a Python/Django app, and patches `settings.py` to parse the Heroku
DATABASE_URL config vars. It then sets default process types to use the Django
web server and console.

External Language Pack
----------------------
Cutting-edge development is taking place in this repo. To use this on Heroku,
set a `LANGUAGE_PACK_URL` config var with a fully authenticated URL to this repo:

    $ heroku config:add LANGUAGE_PACK_URL=https://nzoschke:XXXXXXX@github.com/heroku/language-pack-python.git

On next push, slug-compiler will use this LP instead of the built-in one.