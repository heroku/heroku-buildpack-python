#!/usr/bin/env bash

set -euo pipefail

# Print any path like strings in the files created by build backends for editable installs,
# so we can check that the buildpack rewrote the paths correctly for build vs runtime.
(
	cd .heroku/python/lib/python*/site-packages/
	shopt -s nullglob
	grep --extended-regexp --only-matching --with-filename -- '/\S+' *.pth *editable*.py | LC_ALL=C sort
)
echo

echo -n "Running project entrypoint: "
project-entrypoint

echo -n "Running setuptools flat package entrypoint: "
setuptools-flat

echo -n "Running hatchling default package entrypoint: "
hatchling-default

# TODO: Remove the fallback once bin/compile also rewrites the paths in hatchling's `dev-mode-exact`
# hook module, which is currently left pointing at the build directory (so fails at runtime).
echo -n "Running hatchling exact package entrypoint: "
hatchling-exact 2>/dev/null || echo "FAILED"

echo -n "Running import of VCS package: "
python -c 'import extension; print("OK")'
