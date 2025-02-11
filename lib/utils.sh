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
	local python_major_version="${2}"

	local bundled_wheels_dir="${python_home}/lib/python${python_major_version}/ensurepip/_bundled"

	# We have to use a glob since the bundled wheel filename contains the pip version, which differs
	# between Python versions. We use compgen to avoid having to set nullglob, since there may be no
	# matches in the case of a broken Python install. We also have to handle the case where there are
	# multiple matching pip wheels, since in some versions of Python (eg 3.9.0) multiple versions of
	# pip were accidentally bundled upstream (we use tail since we want the newest pip version).
	if bundled_pip_wheel="$(compgen -G "${bundled_wheels_dir}/pip-*.whl" | tail --lines=1)"; then
		# The pip module exists inside the pip wheel (which is a zip file), however, Python can load
		# it directly by appending the module name to the zip filename, as though it were a path.
		echo "${bundled_pip_wheel}/pip"
	else
		output::error <<-EOF
			Internal Error: Unable to locate the bundled copy of pip.

			The Python buildpack could not locate the copy of pip bundled
			inside Python's 'ensurepip' module:

			$(find "${bundled_wheels_dir}/" 2>&1 || find "${python_home}/" -type d 2>&1 || true)
		EOF
		meta_set "failure_reason" "bundled-pip-not-found"
		exit 1
	fi
}

function utils::abort_internal_error() {
	local message
	message="${1} (line $(caller || true))"
	output::error <<-EOF
		Internal error: ${message}.
	EOF
	meta_set "failure_reason" "internal-error"
	meta_set "failure_detail" "${message}"
	exit 1
}
