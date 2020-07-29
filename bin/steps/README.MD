# Python Buildpack Install Steps

TODO: Add context on Python install steps, such as why symlinking vs copying

## Installing Python packages using Pip

### Convention: Use `python` process to invoke Pip

We don't use this convention (yet) but this is an upcoming change being considered.

This is a bigger concern on Windows than it is in Linux environments, but an
emerging convention in the Python community is to invoke pip using:

```
python3 -m pip [options]
```

Invoking pip this way ensures correct location - python knows where these
packages are stored because it put them there (defaults to Python's pathing info).

All normal command line options are available using this method.
