#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

ANSI_BLUE='\033[1;34m'
ANSI_RED='\033[1;31m'
ANSI_YELLOW='\033[1;33m'
ANSI_RESET='\033[0m'

# Output a single line step message to stdout.
#
# Usage:
# ```
# output::step "Installing Python ..."
# ```
function output::step() {
	echo "-----> ${1}"
}

# Indent passed stdout. Typically used to indent command output within a step.
#
# Usage:
# ```
# pip install ... | output::indent
# ```
function output::indent() {
	sed --unbuffered "s/^/       /"
}

# Output a styled multi-line notice message to stderr.
#
# Usage:
# ```
# output::notice <<-EOF
# 	Note: The note summary.
#
# 	Detailed description.
# EOF
# ```
function output::notice() {
	echo >&2
	while IFS= read -r line; do
		echo -e "${ANSI_BLUE} !     ${line}${ANSI_RESET}" >&2
	done
	echo >&2
}

# Output a styled multi-line warning message to stderr.
#
# Usage:
# ```
# output::warning <<-EOF
# 	Warning: The warning summary.
#
# 	Detailed description.
# EOF
# ```
function output::warning() {
	echo >&2
	while IFS= read -r line; do
		echo -e "${ANSI_YELLOW} !     ${line}${ANSI_RESET}" >&2
	done
	echo >&2
}

# Output a styled multi-line error message to stderr.
#
# Usage:
# ```
# output::error <<-EOF
# 	Error: The error summary.
#
# 	Detailed description.
# EOF
# ```
function output::error() {
	echo >&2
	while IFS= read -r line; do
		echo -e "${ANSI_RED} !     ${line}${ANSI_RESET}" >&2
	done
	echo >&2
}
