# This tests a legacy package that has only a `setup.py` and no `pyproject.toml`, using a flat layout
# (the package directory is next to this file, rather than under `src/`). Setuptools installs flat
# layouts in editable mode using an `__editable___*_finder.py` file (containing absolute paths)
# instead of the static `.pth` file that the `src` layout of the root project results in.

from setuptools import setup

setup(
    name="setuptools-flat",
    version="0.0.0",
    packages=["setuptools_flat"],
    entry_points={"console_scripts": ["setuptools-flat = setuptools_flat:main"]},
)
