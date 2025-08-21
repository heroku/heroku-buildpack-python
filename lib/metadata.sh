#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

METADATA_FILE="${CACHE_DIR:?}/build-data/python.json"
PREVIOUS_METADATA_FILE="${CACHE_DIR:?}/build-data/python-prev.json"

# Legacy `key=value` format file used by older Python buildpack versions.
LEGACY_BUILD_DATA_FILE="${CACHE_DIR:?}/build-data/python"

# Initializes the metadata store, preserving the file from the previous build if it exists.
# Call this at the start of `bin/compile` before using any other functions from this file.
#
# Usage:
# ```
# metadata::setup
# ```
function metadata::setup() {
	if [[ -f "${METADATA_FILE}" ]]; then
		# Rename the existing metadata file rather than overwriting it, so we can lookup values
		# from the previous build (such as when determining whether to invalidate the cache).
		mv "${METADATA_FILE}" "${PREVIOUS_METADATA_FILE}"
	else
		mkdir -p "$(dirname "${METADATA_FILE}")"
	fi

	echo "{}" >"${METADATA_FILE}"
}

# Retrieve the value of an entry in the metadata store for the current build.
# Returns the empty string if the key wasn't found in the store.
#
# Usage:
# ```
# metadata::get "python_version"
# ```
function metadata::get() {
	local key="${1}"
	jq --raw-output ".${key} // empty" "${METADATA_FILE}"
}

# Retrieve the value of an entry in the metadata store from the previous successful build.
# Returns the empty string if the key wasn't found in the store.
#
# Usage:
# ```
# metadata::get_previous "python_version"
# ```
function metadata::get_previous() {
	local key="${1}"

	# Older versions of this buildpack used a `key=value` format file instead of JSON,
	# so we need to support this file format/location too, so older caches can be read.
	# We check for this file first, so that we correctly handle the case where an app
	# downgraded and then re-upgraded buildpack version, so has both files in the cache.
	if [[ -f "${LEGACY_BUILD_DATA_FILE}" ]]; then
		# The legacy file contains one entry per line, of form `key=value`. Entries were written in an
		# append-only manner so there could be duplicate entries for each key, so we return only the
		# last matching entry in the file. The empty string is returned if the key wasn't found.
		tac "${LEGACY_BUILD_DATA_FILE}" | { grep --perl-regexp --only-matching --max-count=1 "^${key}=\K.*$" || true; }
	elif [[ -f "${PREVIOUS_METADATA_FILE}" ]]; then
		# The `// empty` ensures we return the empty string rather than `null` if the key doesn't exist.
		jq --raw-output ".${key} // empty" "${PREVIOUS_METADATA_FILE}"
	fi
}

# Sets a string metadata value. The value will be wrapped in double quotes and escaped for JSON.
#
# Usage:
# ```
# metadata::set_string "python_version" "1.2.3"
# metadata::set_string "failure_reason" "install-dependencies::pip"
# ```
function metadata::set_string() {
	local key="${1}"
	local value="${2}"
	metadata::_set "${key}" "${value}" "true"
}

# Sets a metadata value for the elapsed time in seconds between the provided start time and the
# current time, represented as a float with milliseconds precision.
#
# Usage:
# ```
# local dependencies_install_start_time=$(metadata::current_unix_time_ms)
# # ... some operation ...
# metadata::set_duration "dependencies_install_duration" "${dependencies_install_start_time}"
# ```
function metadata::set_duration() {
	local key="${1}"
	local start_time="${2}"
	local end_time duration
	end_time="$(metadata::current_unix_time_ms)"
	duration="$(awk -v start="${start_time}" -v end="${end_time}" 'BEGIN { printf "%.3f", (end - start)/1000 }')"
	metadata::set_raw "${key}" "${duration}"
}

# Sets a metadata value as raw JSON data. The value parameter must be valid JSON value, that's also
# a supported Honeycomb data type (string, integer, float, or boolean only; no arrays or objects).
# For strings, use `metadata::set_string` instead since it will handle the escaping/quoting for you.
# And for durations, use `metadata::set_duration`.
#
# Usage:
# ```
# metadata::set_raw "python_version_outdated" "true"
# metadata::set_raw "foo_size_mb" "42.5"
# ```
function metadata::set_raw() {
	local key="${1}"
	local value="${2}"
	metadata::_set "${key}" "${value}" "false"
}

# Internal helper to write a key/value pair to the metadata store. The buildpack shouldn't call this directly.
# Takes a key, value, and a boolean flag indicating whether the value needs to be quoted.
#
# Usage:
# ```
# metadata::_set "foo_string" "quote me" "true"
# metadata::_set "bar_number" "99" "false"
# ```
function metadata::_set() {
	local key="${1}"
	# Truncate the value to an arbitrary 200 characters since it will sometimes contain user-provided
	# inputs which may be unbounded in size. Ideally individual call sites will perform more aggressive
	# truncation themselves based on the expected value size, however this is here as a fallback.
	# (Honeycomb supports string fields up to 64KB in size, however, it's not worth filling up the
	# metadata store or bloating the payload passed back to Vacuole/submitted to Honeycomb given the
	# extra content in those cases is not normally useful.)
	local value="${2:0:200}"
	local needs_quoting="${3}"

	if [[ "${needs_quoting}" == "true" ]]; then
		# Values passed using `--arg` are treated as strings, and so have double quotes added and any JSON
		# special characters (such as newlines, carriage returns, double quotes, backslashes) are escaped.
		local jq_args=(--arg value "${value}")
	else
		# Values passed using `--argjson` are treated as raw JSON values, and so aren't escaped or quoted.
		local jq_args=(--argjson value "${value}")
	fi

	local new_data_file_contents
	new_data_file_contents=$(jq --arg key "${key}" "${jq_args[@]}" '. + { ($key): ($value) }' "${METADATA_FILE}")
	echo "${new_data_file_contents}" >"${METADATA_FILE}"
}

# Returns the current time in milliseconds since the UNIX Epoch.
#
# Usage:
# ```
# local dependencies_install_start_time=$(metadata::current_unix_time_ms)
# # ... some operation ...
# metadata::set_duration "dependencies_install_duration" "${dependencies_install_start_time}"
# ```
function metadata::current_unix_time_ms() {
	date +%s%3N
}

# Prints the contents of the metadata store in sorted JSON format.
#
# Usage:
# ```
# metadata::print_bin_report_json
# ```
function metadata::print_bin_report_json() {
	jq --sort-keys '.' "${METADATA_FILE}"
}
