#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

LATEST_PYTHON_3_8="3.8.20"
LATEST_PYTHON_3_9="3.9.20"
LATEST_PYTHON_3_10="3.10.15"
LATEST_PYTHON_3_11="3.11.10"
LATEST_PYTHON_3_12="3.12.7"
LATEST_PYTHON_3_13="3.13.0"

DEFAULT_PYTHON_FULL_VERSION="${LATEST_PYTHON_3_12}"
DEFAULT_PYTHON_MAJOR_VERSION="${DEFAULT_PYTHON_FULL_VERSION%.*}"

# Integer with no redundant leading zeros.
INT_REGEX="(0|[1-9][0-9]*)"
# Versions of form N.N or N.N.N.
PYTHON_VERSION_REGEX="${INT_REGEX}\.${INT_REGEX}(\.${INT_REGEX})?"
# Versions of form N.N.N only.
PYTHON_FULL_VERSION_REGEX="${INT_REGEX}\.${INT_REGEX}\.${INT_REGEX}"

# Determine what Python version has been requested for the project.
#
# Returns a version request of form N.N or N.N.N, with basic validation checks that the version
# matches those forms. EOL version checks will be performed later, when this version request is
# resolved to an exact Python version.
#
# If an app specifies the Python version via multiple means, then the order of precedence is:
# 1. runtime.txt
# 2. Pipfile.lock (`python_full_version` field)
# 3. Pipfile.lock (`python_version` field)
#
# If a version wasn't specified by the app, then new apps/those with an empty cache will use
# a buildpack default version for the first build, and then subsequent cached builds will use
# the same Python full version in perpetuity (aka sticky versions). Sticky versioning leads to
# confusing UX so is something we want to deprecate/sunset in the future (and have already done
# so in the Python CNB).
# TODO: Change the sticky versioning implementation so it's only sticky to the major version
# rather than the full version, so apps that don't specify a Python version at least get
# security patch updates.
function python_version::read_requested_python_version() {
	local build_dir="${1}"
	local package_manager="${2}"
	local cached_python_version="${3}"
	# We use the Bash 4.3+ `nameref` feature to pass back multiple values from this function
	# without having to hardcode globals. See: https://stackoverflow.com/a/38997681
	declare -n version="${4}"
	declare -n origin="${5}"
	local contents

	local runtime_txt_path="${build_dir}/runtime.txt"
	if [[ -f "${runtime_txt_path}" ]]; then
		contents="$(cat "${runtime_txt_path}")"
		version="$(python_version::parse_runtime_txt "${contents}")"
		origin="runtime.txt"
		return 0
	fi

	if [[ "${package_manager}" == "pipenv" ]]; then
		version="$(python_version::read_pipenv_python_version "${build_dir}")"
		# The Python version fields in a Pipfile.lock are optional.
		if [[ -n "${version}" ]]; then
			origin="Pipfile.lock"
			return 0
		fi
	fi

	# Protect against invalid versions somehow having been written into the cache.
	# TODO: Move this validation into the cache handling as part of the cache refactor?
	if [[ "${cached_python_version}" =~ ^${PYTHON_VERSION_REGEX}$ ]]; then
		version="${cached_python_version}"
		origin="cached"
	else
		version="${DEFAULT_PYTHON_MAJOR_VERSION}"
		# shellcheck disable=SC2034 # This isn't unused, Shellcheck doesn't follow namerefs.
		origin="default"
	fi
}

# Parse the contents of a runtime.txt file and return the Python version substring (e.g. `3.12.0`).
function python_version::parse_runtime_txt() {
	local contents="${1}"

	# The file must contain a string of form `python-N.N.N` (leading/trailing whitespace is permitted).
	if [[ "${contents}" =~ ^[[:space:]]*python-(${PYTHON_FULL_VERSION_REGEX})[[:space:]]*$ ]]; then
		local version="${BASH_REMATCH[1]}"
		echo "${version}"
	else
		display_error <<-EOF
			Error: Invalid Python version in runtime.txt.

			The Python version specified in 'runtime.txt' is not in
			the correct format.

			The following file contents were found:
			${contents}

			However, the version string must begin with a 'python-' prefix,
			followed by the version specified as '<major>.<minor>.<patch>'.
			Comments are not supported.

			For example, to request Python ${DEFAULT_PYTHON_FULL_VERSION}, use:
			python-${DEFAULT_PYTHON_FULL_VERSION}

			Please update 'runtime.txt' to use a valid version string, or
			else remove the file to instead use the default version
			(currently Python ${DEFAULT_PYTHON_FULL_VERSION}).
		EOF
		meta_set "failure_reason" "python-version-invalid"
		return 1
	fi
}

# Read the Python version from a Pipfile.lock, which can exist in one of two optional fields,
# `python_full_version` (as N.N.N) and `python_version` (as N.N). If both fields are
# defined, we will use the value set in `python_full_version`. See:
# https://pipenv.pypa.io/en/latest/specifiers.html#specifying-versions-of-python
function python_version::read_pipenv_python_version() {
	local build_dir="${1}"
	local pipfile_lock_path="${build_dir}/Pipfile.lock"
	local version

	# We currently permit using Pipenv without a `Pipfile.lock`, however, in the future we will
	# require a lockfile, at which point this conditional can be removed.
	if [[ ! -f "${pipfile_lock_path}" ]]; then
		return 0
	fi

	if ! version=$(jq --raw-output '._meta.requires.python_full_version // ._meta.requires.python_version' "${pipfile_lock_path}" 2>&1); then
		display_error <<-EOF
			Error: Cannot parse Pipfile.lock.

			A Pipfile.lock file was found, however, it could not be parsed:
			${version}

			This is likely due to it not being valid JSON.

			Run 'pipenv lock' to regenerate/fix the lockfile.
		EOF
		meta_set "failure_reason" "pipfile-lock-invalid"
		return 1
	fi

	# Neither of the optional fields were found.
	if [[ "${version}" == "null" ]]; then
		return 0
	fi

	# We don't use separate version validation rules for both fields (e.g. ensuring a patch version
	# only exists for `python_full_version`) since Pipenv doesn't distinguish between them either:
	# https://github.com/pypa/pipenv/blob/v2024.1.0/pipenv/project.py#L392-L398
	if [[ "${version}" =~ ^${PYTHON_VERSION_REGEX}$ ]]; then
		echo "${version}"
	else
		display_error <<-EOF
			Error: Invalid Python version in Pipfile / Pipfile.lock.

			The Python version specified in Pipfile / Pipfile.lock by the
			'python_version' or 'python_full_version' field is not valid.

			The following version was found:
			${version}

			However, the version must be specified as either:
			1. '<major>.<minor>' (recommended, for automatic security updates)
			2. '<major>.<minor>.<patch>' (to pin to an exact Python version)

			Please update your 'Pipfile' to use a valid Python version and
			then run 'pipenv lock' to regenerate the lockfile.

			For more information, see:
			https://pipenv.pypa.io/en/latest/specifiers.html#specifying-versions-of-python
		EOF
		meta_set "failure_reason" "python-version-invalid"
		return 1
	fi
}

# Resolve a requested Python version (which can be of form N.N or N.N.N) to a specific
# Python version of form N.N.N. Rejects Python major versions that are not supported.
function python_version::resolve_python_version() {
	local requested_python_version="${1}"
	local python_version_origin="${2}"

	if [[ ! "${requested_python_version}" =~ ^${PYTHON_VERSION_REGEX}$ ]]; then
		# The Python version was previously validated, so this should never occur.
		utils::abort_internal_error "Invalid Python version: ${requested_python_version}"
	fi

	local major="${BASH_REMATCH[1]}"
	local minor="${BASH_REMATCH[2]}"

	if ((major < 3 || (major == 3 && minor < 8))); then
		if [[ "${python_version_origin}" == "cached" ]]; then
			display_error <<-EOF
				Error: The cached Python version has reached end-of-life.

				Your app does not specify a Python version, and so normally
				would use the version cached from the last build (${requested_python_version}).

				However, Python ${major}.${minor} has reached its upstream end-of-life,
				and is therefore no longer receiving security updates:
				https://devguide.python.org/versions/#supported-versions

				As such, it is no longer supported by this buildpack.

				Please upgrade to a newer Python version by creating a
				'runtime.txt' file that contains a Python version like:
				python-${DEFAULT_PYTHON_FULL_VERSION}

				For a list of the supported Python versions, see:
				https://devcenter.heroku.com/articles/python-support#supported-runtimes
			EOF
		else
			display_error <<-EOF
				Error: The requested Python version has reached end-of-life.

				Python ${major}.${minor} has reached its upstream end-of-life, and is
				therefore no longer receiving security updates:
				https://devguide.python.org/versions/#supported-versions

				As such, it is no longer supported by this buildpack.

				Please upgrade to a newer Python version by updating the
				version configured via the '${python_version_origin}' file.

				For a list of the supported Python versions, see:
				https://devcenter.heroku.com/articles/python-support#supported-runtimes
			EOF
		fi
		meta_set "failure_reason" "python-version-eol"
		return 1
	fi

	if (((major == 3 && minor > 13) || major >= 4)); then
		if [[ "${python_version_origin}" == "cached" ]]; then
			display_error <<-EOF
				Error: The cached Python version is not recognised.

				Your app does not specify a Python version, and so normally
				would use the version cached from the last build (${requested_python_version}).

				However, Python ${major}.${minor} is not recognised by this version
				of the buildpack.

				This can occur if you have downgraded the version of the
				buildpack to an older version.

				Please switch back to a newer version of this buildpack.
			EOF
		else
			display_error <<-EOF
				Error: The requested Python version is not recognised.

				The requested Python version ${major}.${minor} is not recognised.

				Check that this Python version has been officially released,
				and that the Python buildpack has added support for it:
				https://devguide.python.org/versions/#supported-versions
				https://devcenter.heroku.com/articles/python-support#supported-runtimes

				If it has, make sure that you are using the latest version
				of this buildpack:
				https://devcenter.heroku.com/articles/python-support#checking-the-python-buildpack-version

				Otherwise, switch to a supported version (such as Python ${DEFAULT_PYTHON_MAJOR_VERSION})
				by updating the version configured via the '${python_version_origin}' file.
			EOF
		fi
		meta_set "failure_reason" "python-version-unknown"
		return 1
	fi

	# If an exact Python version was requested, there's nothing to resolve.
	# Otherwise map major version specifiers to the latest patch release.
	case "${requested_python_version}" in
		*.*.*) echo "${requested_python_version}" ;;
		3.8) echo "${LATEST_PYTHON_3_8}" ;;
		3.9) echo "${LATEST_PYTHON_3_9}" ;;
		3.10) echo "${LATEST_PYTHON_3_10}" ;;
		3.11) echo "${LATEST_PYTHON_3_11}" ;;
		3.12) echo "${LATEST_PYTHON_3_12}" ;;
		3.13) echo "${LATEST_PYTHON_3_13}" ;;
		*) utils::abort_internal_error "Unhandled Python major version: ${requested_python_version}" ;;
	esac
}
