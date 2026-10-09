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

echo -n "Running import of VCS package: "
python -c 'import extension; print("OK")'
