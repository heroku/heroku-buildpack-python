#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# The requirement versions are effectively buildpack constants, however, we want
# Dependabot to be able to update them, which requires that they be in requirements
# files. The requirements files contain contents like `package==1.2.3` (and not just
# the package version) so we have to extract the version substring from it.
function utils::get_requirement_version() {
	local package_name="${1}"
	local requirement
	requirement=$(cat "${BUILDPACK_DIR:?}/requirements/${package_name}.txt")
	local requirement_version="${requirement#"${package_name}=="}"
	echo "${requirement_version}"
}

# Python bundles pip within its standard library, which we can use to install our chosen
# pip version from PyPI, saving us from having to download the usual pip bootstrap script.
function utils::bundled_pip_module_path() {
	local python_home="${1}"

	# We have to use a glob since the bundled wheel filename contains the pip version, which
	# differs between Python versions. We also have to handle the case where there are multiple
	# matching pip wheels, since in some versions of Python (eg 3.9.0) multiple versions of pip
	# were accidentally bundled upstream. Note: This implementation relies upon `nullglob` being
	# set, which is the case thanks to the `bin/utils` that was run earlier.
	local bundled_pip_wheel_list=("${python_home}"/lib/python*/ensurepip/_bundled/pip-*.whl)
	local bundled_pip_wheel="${bundled_pip_wheel_list[0]}"

	if [[ -z "${bundled_pip_wheel}" ]]; then
		output::error <<-'EOF'
			Error: Failed to locate the bundled pip wheel.
		EOF
		meta_set "failure_reason" "bundled-pip-not-found"
		return 1
	fi

	echo "${bundled_pip_wheel}/pip"
}

function utils::abort_internal_error() {
	local message="${1}"
	output::error <<-EOF
		Internal error: ${message} (line $(caller || true)).
	EOF
	meta_set "failure_reason" "internal-error"
	exit 1
}
