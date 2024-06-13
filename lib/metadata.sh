#!/usr/bin/env bash

# Based on: https://github.com/heroku/heroku-buildpack-nodejs/blob/main/lib/metadata.sh

source "${BUILDPACK_DIR}/lib/kvstore.sh"

# Variables shared by this whole module
BUILD_DATA_FILE=""
PREVIOUS_BUILD_DATA_FILE=""

# Must be called before you can use any other methods
meta_init() {
  local cache_dir="${1}"
  local buildpack_name="${2}"
  BUILD_DATA_FILE="${cache_dir}/build-data/${buildpack_name}"
  PREVIOUS_BUILD_DATA_FILE="${cache_dir}/build-data/${buildpack_name}-prev"
}

# Moves the data from the last build into the correct place, and clears the store
# This should be called after meta_init in bin/compile
meta_setup() {
  # if the file already exists because it's from the last build, save it
  if [[ -f "${BUILD_DATA_FILE}" ]]; then
    cp "${BUILD_DATA_FILE}" "${PREVIOUS_BUILD_DATA_FILE}"
  fi

  kv_create "${BUILD_DATA_FILE}"
  kv_clear "${BUILD_DATA_FILE}"
}

# Force removal of exiting data file state. This is mostly useful during testing and not
# expected to be used during buildpack execution.
meta_force_clear() {
  [[ -f "${BUILD_DATA_FILE}" ]] && rm "${BUILD_DATA_FILE}"
  [[ -f "${PREVIOUS_BUILD_DATA_FILE}" ]] && rm "${PREVIOUS_BUILD_DATA_FILE}"
}

meta_get() {
  kv_get "${BUILD_DATA_FILE}" "${1}"
}

meta_set() {
  kv_set "${BUILD_DATA_FILE}" "${1}" "${2}"
}

# Similar to mtime from buildpack-stdlib
meta_time() {
  local key="${1}"
  local start="${2}"
  local end="${3:-$(nowms)}"
  local time
  time="$(echo "${start}" "${end}" | awk '{ printf "%.3f", ($2 - $1)/1000 }')"
  kv_set "${BUILD_DATA_FILE}" "${key}" "${time}"
}

# Retrieve a value from a previous build if it exists
# This is useful to give the user context about what changed if the
# build has failed. Ex:
#   - changed stacks
#   - deployed with a new major version of Node
#   - etc
meta_prev_get() {
  kv_get "${PREVIOUS_BUILD_DATA_FILE}" "${1}"
}

log_meta_data() {
  # print all values on one line in logfmt format
  # https://brandur.org/logfmt
  # the echo call ensures that all values are printed on a single line
  # shellcheck disable=SC2005 disable=SC2046
  echo $(kv_list "${BUILD_DATA_FILE}")
}
