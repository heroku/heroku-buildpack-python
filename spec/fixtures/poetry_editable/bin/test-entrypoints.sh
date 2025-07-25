#!/usr/bin/env bash

set -euo pipefail

cd .heroku/python/lib/python*/site-packages/

# List any path like strings in the .pth and finder files in site-packages.
grep --extended-regexp --only-matching -- '/\S+' *.pth __editable___*_finder.py | sort
echo

echo -n "Running entrypoint for the current package: "
poetry-editable

echo -n "Running entrypoint for the pyproject.toml-based local package: "
local_package_pyproject_toml

echo -n "Running entrypoint for the setup.py-based local package: "
local_package_setup_py

echo -n "Running entrypoint for the VCS package: "
gunicorn --version
