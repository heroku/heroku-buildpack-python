#!/usr/bin/env bash

# TODO: Switch this file to using namespaced functions like `output::<fn_name>`.

ANSI_RED='\033[1;31m'
ANSI_RESET='\033[0m'

# shellcheck disable=SC2120 # Prevent warnings about unused arguments due to the split args vs stdin API.
function display_error() {
	# Send all output to stderr
	exec 1>&2
	# If arguments are given, redirect them to stdin. This allows the function
	# to be invoked with either a string argument or stdin (e.g. via <<-EOF).
	(($#)) && exec <<<"${@}"
	echo
	while IFS= read -r line; do
		echo -e "${ANSI_RED} !     ${line}${ANSI_RESET}"
	done
	echo
}
