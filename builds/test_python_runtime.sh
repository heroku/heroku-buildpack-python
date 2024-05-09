#!/usr/bin/env bash

set -euo pipefail

ARCHIVE_FILEPATH="${1:?"Error: The filepath of the Python runtime archive must be specified as the first argument."}"

# We intentionally extract the Python runtime into a different directory to the one into which it
# was originally installed before being packaged, to check that relocation works (since buildpacks
# depend on it). Since the Python binary was built in shared mode, `LD_LIBRARY_PATH` must be set
# when relocating, so the Python binary (which itself contains very little) can find `libpython`.
INSTALL_DIR=$(mktemp -d)
PYTHON="${INSTALL_DIR}/bin/python"
export LD_LIBRARY_PATH="${INSTALL_DIR}/lib/"

tar --zstd --extract --verbose --file "${ARCHIVE_FILEPATH}" --directory "${INSTALL_DIR}"

# Check Python is usable via the `python` symlink (and not just `python3`) and can start.
"${PYTHON}" --version

# Check that all dynamically linked libraries exist in the run image (since it has fewer packages than the build image).
if find "${INSTALL_DIR}" -name '*.so' -exec ldd '{}' + | grep 'not found'; then
  echo "The above dynamically linked libraries were not found!"
  exit 1
fi

# Check that optional and/or system library dependent stdlib modules were built.
optional_stdlib_modules=(
  _uuid
  bz2
  ctypes
  curses
  dbm.gnu
  dbm.ndbm
  decimal
  lzma
  readline
  sqlite3
  ssl
  xml.parsers.expat
  zlib
)
if ! "${PYTHON}" -c "import $(IFS=, ; echo "${optional_stdlib_modules[*]}")"; then
  echo "The above optional stdlib module failed to import! Check the compile logs to see if it was skipped due to missing libraries/headers."
  exit 1
fi
