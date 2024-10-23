#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Python bundles pip within its standard library, which we can use to install our chosen
# pip version from PyPI, saving us from having to download the usual pip bootstrap script.
function utils::bundled_pip_module_path() {
	local build_dir="${1}"

	# We have to use a glob since the bundled wheel filename contains the pip version, which
	# differs between Python versions. We also have to handle the case where there are multiple
	# matching pip wheels, since in some versions of Python (eg 3.9.0) multiple versions of pip
	# were accidentally bundled upstream. Note: This implementation relies upon `nullglob` being
	# set, which is the case thanks to the `bin/utils` that was run earlier.
	local bundled_pip_wheel_list=("${build_dir}"/.heroku/python/lib/python*/ensurepip/_bundled/pip-*.whl)
	local bundled_pip_wheel="${bundled_pip_wheel_list[0]}"

	if [[ -z "${bundled_pip_wheel}" ]]; then
		output::error "Error: Failed to locate the bundled pip wheel."
		meta_set "failure_reason" "bundled-pip-not-found"
		return 1
	fi

	echo "${bundled_pip_wheel}/pip"
}

function utils::abort_internal_error() {
	local message="${1}"
	output::error "Internal error: ${message} (line $(caller || true))."
	meta_set "failure_reason" "internal-error"
	exit 1
}
