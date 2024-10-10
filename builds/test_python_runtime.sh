#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit

ARCHIVE_FILEPATH="${1:?"Error: The filepath of the Python runtime archive must be specified as the first argument."}"

function abort() {
	echo "Error: ${1}" >&2
	exit 1
}

set -x

# We intentionally extract the Python runtime into a different directory to the one into which it
# was originally installed before being packaged, to check that relocation works (since buildpacks
# depend on it). Since the Python binary was built in shared mode, `LD_LIBRARY_PATH` must be set
# when relocating, so the Python binary (which itself contains very little) can find `libpython`.
INSTALL_DIR=$(mktemp -d)
export LD_LIBRARY_PATH="${INSTALL_DIR}/lib/"

tar --zstd --extract --verbose --file "${ARCHIVE_FILEPATH}" --directory "${INSTALL_DIR}"

# Check Python is able to start and is usable via both the default `python3` command and the
# `python` symlink we create during the build. We use the full filepath rather than adding the
# directory to PATH to ensure the test doesn't pass because of falling through to system Python.
"${INSTALL_DIR}/bin/python3" --version
"${INSTALL_DIR}/bin/python" --version

# Check the Python config script still exists/works after the deletion of scripts with broken shebang lines.
"${INSTALL_DIR}/bin/python3-config" --help

set +x

# Check that the broken bin entrypoints and symlinks (such as `idle3` and `pydoc3`) were deleted.
UNEXPECTED_BIN_FILES="$(find "${INSTALL_DIR}/bin" -type 'f,l' -not -name 'python*')"
if [[ -n "${UNEXPECTED_BIN_FILES}" ]]; then
	echo "${UNEXPECTED_BIN_FILES}"
	abort "The above files were found in the bin/ directory but were not expected!"
else
	echo "No unexpected files found in the bin/ directory."
fi

# Check that all dynamically linked libraries exist in the run image (since it has fewer packages than the build image).
LDD_OUTPUT=$(find "${INSTALL_DIR}" -type f,l \( -name 'python3' -o -name '*.so*' \) -exec ldd '{}' +)
if grep 'not found' <<<"${LDD_OUTPUT}" | sort --unique; then
	abort "The above dynamically linked libraries were not found!"
else
	echo "All dynamically linked libraries were found."
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
if "${INSTALL_DIR}/bin/python3" -c "import $(
	IFS=,
	echo "${optional_stdlib_modules[*]}"
)"; then
	echo "Successful imported: ${optional_stdlib_modules[*]}"
else
	abort "The above optional stdlib module failed to import! Check the compile logs to see if it was skipped due to missing libraries/headers."
fi
