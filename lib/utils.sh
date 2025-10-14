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

# Replaces any invisible unwanted characters (such as ASCII control codes) with the Unicode
# replacement character, so they are visible in error messages. Also removes any carriage
# return characters, to prevent them interfering with the rendering of error messages that
# include the raw file contents.
function utils::read_file_with_special_chars_substituted() {
	local file="${1}"
	sed --regexp-extended --expression 's/[^[:print:][:space:]]/�/g' --expression 's/\r$//' "${file}"
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
			Internal Error: Unable to locate the Python stdlib's bundled pip.

			Couldn't find the pip wheel file bundled inside the Python
			stdlib's 'ensurepip' module:

			$(find "${bundled_wheels_dir}/" 2>&1 || find "${python_home}/" -type d 2>&1 || true)
		EOF
		build_data::set_string "failure_reason" "internal-error::bundled-pip-not-found"
		exit 1
	fi
}

function utils::abort_internal_error() {
	local message
	message="${1} (line $(caller || true))"
	output::error <<-EOF
		Internal error: ${message}.
	EOF
	build_data::set_string "failure_reason" "internal-error::abort"
	build_data::set_string "failure_detail" "${message}"
	exit 1
}

function utils::err_trap() {
	# We use `errtrace` which means the ERR trap can fire multiple times, such as when an error
	# occurs in a buildpack function called from within a command substitution.
	# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
	if build_data::has "failure_reason"; then
		return
	fi

	local failing_command="${BASH_COMMAND}"
	local stack_trace
	stack_trace=$(
		local frame=0
		while read -r line_number function_name source_file < <(caller "${frame}" || true); do
			echo "${function_name} @ ${source_file}:${line_number}"
			((++frame))
		done
	)

	output::error <<-EOF
		Internal Error: An unhandled buildpack error occurred.

		An unhandled error occurred while executing the command:
		${failing_command}

		If this issue persists, please open a support ticket or file
		an issue on the buildpack's GitHub repository:
		https://help.heroku.com/
		https://github.com/heroku/heroku-buildpack-python/issues

		Stack trace:
		${stack_trace}
	EOF
	build_data::set_string "failure_reason" "internal-error::unhandled"
	build_data::set_string "failure_detail" "${failing_command}"
}
