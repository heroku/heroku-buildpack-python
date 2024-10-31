#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# TODO: Switch this file to using namespaced functions like `kvstore::<fn_name>`.

# Taken from: https://github.com/heroku/heroku-buildpack-nodejs/blob/main/lib/kvstore.sh

kv_create() {
	local f="${1}"
	mkdir -p "$(dirname "${f}")"
	touch "${f}"
}

kv_clear() {
	local f="${1}"
	echo "" >"${f}"
}

kv_set() {
	# TODO: Stop ignoring an incorrect number of passed arguments.
	if [[ $# -eq 3 ]]; then
		local f="${1}"
		if [[ -f "${f}" ]]; then
			echo "${2}=${3}" >>"${f}"
		fi
	fi
}

# Returns a key from the key-value store file, or else the empty string
# if the file doesn't exist or the key wasn't found.
kv_get() {
	# TODO: Stop ignoring an incorrect number of passed arguments.
	if [[ $# -eq 2 ]]; then
		local f="${1}"
		if [[ -f "${f}" ]]; then
			# shellcheck disable=SC2310 # This function is invoked in an || condition so set -e will be disabled.
			grep "^${2}=" "${f}" | sed -e "s/^${2}=//" | tail -n 1 || true
		fi
	fi
}

# get the value, but wrap it in quotes if it contains a space
kv_get_escaped() {
	local value
	value=$(kv_get "${1}" "${2}")
	if [[ "${value}" =~ [[:space:]]+ ]]; then
		echo "\"${value}\""
	else
		echo "${value}"
	fi
}

kv_keys() {
	local f="${1}"
	local keys=()

	if [[ -f "${f}" ]]; then
		# Iterate over each line, splitting on the '=' character
		#
		# The || [[ -n "${key}" ]] statement addresses an issue with reading the last line
		# of a file when there is no newline at the end. This will not happen if the file
		# is created with this module, but can happen if it is written by hand.
		# See: https://stackoverflow.com/questions/12916352/shell-script-read-missing-last-line
		while IFS="=" read -r key value || [[ -n "${key}" ]]; do
			# if there are any empty lines in the store, skip them
			if [[ -n "${key}" ]]; then
				keys+=("${key}")
			fi
		done <"${f}"

		echo "${keys[@]}" | tr ' ' '\n' | sort -u
	fi
}

kv_list() {
	local f="${1}"

	kv_keys "${f}" | tr ' ' '\n' | while read -r key; do
		if [[ -n "${key}" ]]; then
			# shellcheck disable=SC2312 # TODO: Invoke this command separately to avoid masking its return value.
			echo "${key}=$(kv_get_escaped "${f}" "${key}")"
		fi
	done
}
