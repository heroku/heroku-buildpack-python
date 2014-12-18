This [custom buildpack](https://github.com/JasonSanford/heroku-buildpack-python-geos) is used to include the GEOS binaries necessary for Shapely. To force deployment to use a custom buildpack, add the following heroku config.

    heroku config:set
BUILDPACK_URL=git://github.com/JasonSanford/heroku-buildpack-python-geos.git

I *think* this buildpack will download/unpack the GEOS binaries each time you deploy which is not ideal. We should probably conditionally download these in the future.


Additionally, the `LIBRARY_PATH` must be updated so that Shapely can locate the necessary binaries.

    heroku config:set LIBRARY_PATH=/app/.heroku/vendor/lib:vendor/geos/geos/lib:vendor/proj/proj/lib:vendor/gdal/gdal/lib
    heroku config:set LD_LIBRARY_PATH=/app/.heroku/vendor/lib:vendor/geos/geos/lib:vendor/proj/proj/lib:vendor/gdal/gdal/lib

    $ ls
    Procfile  requirements.txt  web.py

    $ heroku create --buildpack git://github.com/heroku/heroku-buildpack-python.git

    $ git push heroku master
    ...
    -----> Python app detected
    -----> Installing runtime (python-2.7.8)
    -----> Installing dependencies using pip
           Downloading/unpacking requests (from -r requirements.txt (line 1))
           Installing collected packages: requests
           Successfully installed requests
           Cleaning up...
    -----> Discovering process types
           Procfile declares types -> (none)

You can also add it to upcoming builds of an existing application:

    $ heroku config:add BUILDPACK_URL=git://github.com/heroku/heroku-buildpack-python.git

The buildpack will detect your app as Python if it has the file `requirements.txt` in the root.

It will use Pip to install your dependencies, vendoring a copy of the Python runtime into your slug.

Specify a Runtime
-----------------

You can also provide arbitrary releases Python with a `runtime.txt` file.

    $ cat runtime.txt
    python-3.4.2

Runtime options include:

- python-2.7.8
- python-3.4.2
- pypy-2.4.0 (unsupported, experimental)
- pypy3-2.3.1 (unsupported, experimental)

Other [unsupported runtimes](https://github.com/heroku/heroku-buildpack-python/tree/master/builds/runtimes) are available as well.
