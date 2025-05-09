#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

LATEST_PYTHON_3_9="3.9.22"
LATEST_PYTHON_3_10="3.10.17"
LATEST_PYTHON_3_11="3.11.12"
LATEST_PYTHON_3_12="3.12.10"
LATEST_PYTHON_3_13="3.13.3"

OLDEST_SUPPORTED_PYTHON_3_MINOR_VERSION=9
NEWEST_SUPPORTED_PYTHON_3_MINOR_VERSION=13

DEFAULT_PYTHON_FULL_VERSION="${LATEST_PYTHON_3_13}"
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
# 1. `runtime.txt` file (deprecated)
# 2. `.python-version` file (recommended)
# 3. The `python_full_version` field in the `Pipfile.lock` file
# 4. The `python_version` field in the `Pipfile.lock` file
#
# If a version wasn't specified by the app, then new apps/those with an empty cache will use
# a buildpack default version for the first build, and then subsequent cached builds will use
# the same Python major version in perpetuity (aka sticky versions). Sticky versioning leads to
# confusing UX so is something we want to deprecate/sunset in the future (and have already done
# so in the Python CNB).
function python_version::read_requested_python_version() {
	local build_dir="${1}"
	local package_manager="${2}"
	local cached_python_full_version="${3}"
	# We use the Bash 4.3+ `nameref` feature to pass back multiple values from this function
	# without having to hardcode globals. See: https://stackoverflow.com/a/38997681
	declare -n version="${4}"
	declare -n origin="${5}"
	local contents

	local runtime_txt_path="${build_dir}/runtime.txt"
	if [[ -f "${runtime_txt_path}" ]]; then
		contents="$(utils::read_file_with_special_chars_substituted "${runtime_txt_path}")"
		version="$(python_version::parse_runtime_txt "${contents}")"
		origin="runtime.txt"
		return 0
	fi

	local python_version_file_path="${build_dir}/.python-version"
	if [[ -f "${python_version_file_path}" ]]; then
		contents="$(utils::read_file_with_special_chars_substituted "${python_version_file_path}")"
		version="$(python_version::parse_python_version_file "${contents}")"
		origin=".python-version"
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

	# Protect against unsupported (eg PyPy) or invalid versions being found in the cache metadata.
	if [[ "${cached_python_full_version}" =~ ^${PYTHON_FULL_VERSION_REGEX}$ ]]; then
		local cached_python_major_version="${cached_python_full_version%.*}"
		version="${cached_python_major_version}"
		origin="cached"
	else
		version="${DEFAULT_PYTHON_MAJOR_VERSION}"
		# shellcheck disable=SC2034 # This isn't unused, Shellcheck doesn't follow namerefs.
		origin="default"
	fi
}

# Parse the contents of a runtime.txt file and return the Python version substring (e.g. `3.12` or `3.12.0`).
function python_version::parse_runtime_txt() {
	local contents="${1}"

	# The file must contain a string of form `python-N.N` or `python-N.N.N`.
	# Leading/trailing whitespace is permitted.
	if [[ "${contents}" =~ ^[[:space:]]*python-(${PYTHON_VERSION_REGEX})[[:space:]]*$ ]]; then
		local version="${BASH_REMATCH[1]}"
		echo "${version}"
	else
		local instructions
		instructions="$(python_version::python_version_file_instructions "runtime.txt" "${DEFAULT_PYTHON_MAJOR_VERSION}")"
		output::error <<-EOF
			Error: Invalid Python version in runtime.txt.

			The Python version specified in your runtime.txt file isn't
			in the correct format.

			The following file contents were found, which aren't valid:
			${contents:0:100}

			However, the runtime.txt file is deprecated since it has been
			replaced by the more widely supported .python-version file:
			https://devcenter.heroku.com/changelog-items/3141

			As such, we recommend that you switch to using .python-version
			instead of fixing your runtime.txt file.

			${instructions}
		EOF
		meta_set "failure_reason" "runtime-txt::invalid-version"
		meta_set "failure_detail" "${contents:0:50}"
		exit 1
	fi
}

# Parse the contents of a .python-version file and return the Python version substring (e.g. `3.12` or `3.12.0`).
function python_version::parse_python_version_file() {
	local contents="${1}"
	local version_lines=()

	while IFS= read -r line; do
		# Ignore lines that only contain whitespace and/or comments.
		if [[ ! "${line}" =~ ^[[:space:]]*(#.*)?$ ]]; then
			version_lines+=("${line}")
		fi
	done <<<"${contents}"

	case "${#version_lines[@]}" in
		1)
			local line="${version_lines[0]}"
			if [[ "${line}" =~ ^[[:space:]]*(${PYTHON_VERSION_REGEX})[[:space:]]*$ ]]; then
				local version="${BASH_REMATCH[1]}"
				echo "${version}"
				return 0
			else
				output::error <<-EOF
					Error: Invalid Python version in .python-version.

					The Python version specified in your .python-version file
					isn't in the correct format.

					The following version was found:
					${line}

					However, the Python version must be specified as either:
					1. The major version only, for example: ${DEFAULT_PYTHON_MAJOR_VERSION} (recommended)
					2. An exact patch version, for example: ${DEFAULT_PYTHON_MAJOR_VERSION}.999

					Don't include quotes, a 'python-' prefix or wildcards. Any
					code comments must be on a separate line prefixed with '#'.

					For example, to request the latest version of Python ${DEFAULT_PYTHON_MAJOR_VERSION},
					update your .python-version file so it contains exactly:
					${DEFAULT_PYTHON_MAJOR_VERSION}

					We strongly recommend that you don't specify the Python patch
					version number, since it will pin your app to an exact Python
					version and so stop your app from receiving security updates
					each time it builds.
				EOF
				meta_set "failure_reason" "python-version-file::invalid-version"
				meta_set "failure_detail" "${line:0:50}"
				exit 1
			fi
			;;
		0)
			output::error <<-EOF
				Error: Invalid Python version in .python-version.

				No Python version was found in your .python-version file.

				Update the file so that it contains your app's major Python
				version number. Don't include quotes or a 'python-' prefix.

				For example, to request the latest version of Python ${DEFAULT_PYTHON_MAJOR_VERSION},
				update your .python-version file so it contains exactly:
				${DEFAULT_PYTHON_MAJOR_VERSION}

				If the file already contains a version, check the line doesn't
				begin with a '#', otherwise it will be treated as a comment.
			EOF
			meta_set "failure_reason" "python-version-file::no-version"
			meta_set "failure_detail" "${contents:0:50}"
			exit 1
			;;
		*)
			local first_five_version_lines=("${version_lines[@]:0:5}")
			output::error <<-EOF
				Error: Invalid Python version in .python-version.

				Multiple versions were found in your .python-version file:

				$(
					IFS=$'\n'
					echo "${first_five_version_lines[*]}"
				)

				Update the file so it contains only one Python version.

				For example, to request the latest version of Python ${DEFAULT_PYTHON_MAJOR_VERSION},
				update your .python-version file so it contains exactly:
				${DEFAULT_PYTHON_MAJOR_VERSION}

				If you have added comments to the file, make sure that those
				lines begin with a '#', so that they are ignored.
			EOF
			meta_set "failure_reason" "python-version-file::multiple-versions"
			meta_set "failure_detail" "$(
				IFS=,
				echo "${first_five_version_lines[*]}"
			)"
			exit 1
			;;
	esac
}

# Read the Python version from a Pipfile.lock, which can exist in one of two optional fields,
# `python_full_version` (as N.N.N) and `python_version` (as N.N). If both fields are
# defined, we will use the value set in `python_full_version`. See:
# https://pipenv.pypa.io/en/stable/specifiers.html#specifying-versions-of-python
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
		local jq_error_message="${version}"
		output::error <<-EOF
			Error: Can't parse Pipfile.lock.

			A Pipfile.lock file was found, however, it couldn't be parsed:
			${jq_error_message}

			This is likely due to it not being valid JSON.

			Run 'pipenv lock' to regenerate/fix the lockfile.
		EOF
		meta_set "failure_reason" "pipfile-lock::invalid-json"
		meta_set "failure_detail" "${jq_error_message:0:100}"
		exit 1
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
		output::error <<-EOF
			Error: Invalid Python version in Pipfile.lock.

			The Python version specified in your Pipfile.lock file by the
			'python_version' or 'python_full_version' fields isn't valid.

			The following version was found:
			${version}

			However, the Python version must be specified as either:
			1. The major version only, for example: ${DEFAULT_PYTHON_MAJOR_VERSION} (recommended)
			2. An exact patch version, for example: ${DEFAULT_PYTHON_MAJOR_VERSION}.999

			Wildcards aren't supported.

			Please update your Pipfile to use a valid Python version and
			then run 'pipenv lock' to regenerate Pipfile.lock.

			We strongly recommend that you don't specify the Python patch
			version number, since it will pin your app to an exact Python
			version and so stop your app from receiving security updates
			each time it builds.

			For more information, see:
			https://pipenv.pypa.io/en/stable/specifiers.html#specifying-versions-of-python
		EOF
		meta_set "failure_reason" "pipfile-lock::invalid-version"
		meta_set "failure_detail" "${version:0:50}"
		exit 1
	fi
}

# Resolve a requested Python version (which can be of form N.N or N.N.N) to a specific
# Python version of form N.N.N. Rejects Python major versions that aren't supported.
function python_version::resolve_python_version() {
	local requested_python_version="${1}"
	local python_version_origin="${2}"

	if [[ ! "${requested_python_version}" =~ ^${PYTHON_VERSION_REGEX}$ ]]; then
		# The Python version was previously validated, so this should never occur.
		utils::abort_internal_error "Invalid Python version: ${requested_python_version}"
	fi

	local major="${BASH_REMATCH[1]}"
	local minor="${BASH_REMATCH[2]}"

	if ((major < 3 || (major == 3 && minor < OLDEST_SUPPORTED_PYTHON_3_MINOR_VERSION))); then
		if [[ "${python_version_origin}" == "cached" ]]; then
			local instructions
			instructions="$(python_version::python_version_file_instructions "${python_version_origin}" "3.${OLDEST_SUPPORTED_PYTHON_3_MINOR_VERSION}")"
			output::error <<-EOF
				Error: The cached Python version has reached end-of-life.

				Your app doesn't specify a Python version, and so normally
				would use the version cached from the last build (${requested_python_version}).

				However, Python ${major}.${minor} has reached its upstream end-of-life,
				and is therefore no longer receiving security updates:
				https://devguide.python.org/versions/#supported-versions

				As such, it's no longer supported by this buildpack:
				https://devcenter.heroku.com/articles/python-support#supported-python-versions

				Please upgrade to at least Python 3.${OLDEST_SUPPORTED_PYTHON_3_MINOR_VERSION} by configuring an
				explicit Python version for your app.

				${instructions}
			EOF
		else
			output::error <<-EOF
				Error: The requested Python version has reached end-of-life.

				Python ${major}.${minor} has reached its upstream end-of-life, and is
				therefore no longer receiving security updates:
				https://devguide.python.org/versions/#supported-versions

				As such, it's no longer supported by this buildpack:
				https://devcenter.heroku.com/articles/python-support#supported-python-versions

				Please upgrade to at least Python 3.${OLDEST_SUPPORTED_PYTHON_3_MINOR_VERSION} by changing the
				version in your ${python_version_origin} file.

				If possible, we recommend upgrading all the way to Python ${DEFAULT_PYTHON_MAJOR_VERSION},
				since it contains many performance and usability improvements.
			EOF
		fi
		meta_set "failure_reason" "python-version::eol"
		meta_set "failure_detail" "${major}.${minor}"
		exit 1
	fi

	if (((major == 3 && minor > NEWEST_SUPPORTED_PYTHON_3_MINOR_VERSION) || major >= 4)); then
		if [[ "${python_version_origin}" == "cached" ]]; then
			output::error <<-EOF
				Error: The cached Python version isn't recognised.

				Your app doesn't specify a Python version, and so normally
				would use the version cached from the last build (${requested_python_version}).

				However, Python ${major}.${minor} isn't recognised by this version
				of the buildpack.

				This can occur if you have downgraded the version of the
				buildpack to an older version.

				Please switch back to a newer version of this buildpack:
				https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
				https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

				Alternatively, request an older Python version by creating
				a .python-version file in the root directory of your app,
				that contains a Python version like:
				3.${NEWEST_SUPPORTED_PYTHON_3_MINOR_VERSION}
			EOF
		else
			output::error <<-EOF
				Error: The requested Python version isn't recognised.

				The requested Python version ${major}.${minor} isn't recognised.

				Check that this Python version has been officially released,
				and that the Python buildpack has added support for it:
				https://devguide.python.org/versions/#supported-versions
				https://devcenter.heroku.com/articles/python-support#supported-python-versions

				If it has, make sure that you are using the latest version
				of this buildpack, and haven't pinned to an older release:
				https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
				https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

				Otherwise, switch to a supported version (such as Python 3.${NEWEST_SUPPORTED_PYTHON_3_MINOR_VERSION})
				by changing the version in your ${python_version_origin} file.
			EOF
		fi
		meta_set "failure_reason" "python-version::unknown-major"
		meta_set "failure_detail" "${major}.${minor}"
		exit 1
	fi

	# If an exact Python version was requested, there's nothing to resolve.
	# Otherwise map major version specifiers to the latest patch release.
	case "${requested_python_version}" in
		*.*.*) echo "${requested_python_version}" ;;
		3.9) echo "${LATEST_PYTHON_3_9}" ;;
		3.10) echo "${LATEST_PYTHON_3_10}" ;;
		3.11) echo "${LATEST_PYTHON_3_11}" ;;
		3.12) echo "${LATEST_PYTHON_3_12}" ;;
		3.13) echo "${LATEST_PYTHON_3_13}" ;;
		*) utils::abort_internal_error "Unhandled Python major version: ${requested_python_version}" ;;
	esac
}

function python_version::warn_or_error_if_python_version_file_missing() {
	local python_version_origin="${1}"
	local python_major_version="${2}"

	if [[ "${python_version_origin}" == ".python-version" ]]; then
		return 0
	fi

	local instructions
	instructions="$(python_version::python_version_file_instructions "${python_version_origin}" "${python_major_version}")"

	case "${python_version_origin}" in
		default | cached)
			if [[ "${package_manager}" == "uv" ]]; then
				output::error <<-EOF
					Error: No Python version was specified.

					When using the package manager uv on Heroku, you must specify
					your app's Python version with a .python-version file.

					To add a .python-version file:

					1. Make sure you are in the root directory of your app
					   and not a subdirectory.
					2. Run 'uv python pin ${python_major_version}'
					   (adjust to match your app's major Python version).
					3. Commit the changes to your Git repository using
					   'git add --all' and then 'git commit'.

					Note: We strongly recommend that you don't specify the Python
					patch version number in your .python-version file, since it will
					pin your app to an exact Python version and so stop your app from
					receiving security updates each time it builds.
				EOF
				meta_set "failure_reason" "python-version-file::not-found"
				exit 1
			fi

			output::warning <<-EOF
				Warning: No Python version was specified.

				Your app doesn't specify a Python version and so the buildpack
				picked a default version for you.

				Relying on this default version isn't recommended, since it
				can change over time and may not be consistent with your local
				development environment, CI or other instances of your app.

				Please configure an explicit Python version for your app.

				${instructions}

				If your app already has a .python-version file, check that it:

				1. Is in the top level directory (not a subdirectory).
				2. Is named exactly '.python-version' in all lowercase.
				3. Isn't listed in '.gitignore' or '.slugignore'.
				4. Has been added to the Git repository using 'git add --all'
				   and then committed using 'git commit'.

				In the future we will require the use of a .python-version
				file and this warning will be made an error.
			EOF
			;;
		runtime.txt)
			if [[ "${package_manager}" == "uv" ]]; then
				output::error <<-EOF
					Error: The runtime.txt file isn't supported when using uv.

					When using the package manager uv on Heroku, you must specify
					your app's Python version with a .python-version file and not
					a runtime.txt file.

					To switch to a .python-version file:

					1. Make sure you are in the root directory of your app
					   and not a subdirectory.
					2. Delete your runtime.txt file.
					3. Run 'uv python pin ${python_major_version}'
					   (adjust to match your app's major Python version).
					4. Commit the changes to your Git repository using
					   'git add --all' and then 'git commit'.

					Note: We strongly recommend that you don't specify the Python
					patch version number in your .python-version file, since it will
					pin your app to an exact Python version and so stop your app from
					receiving security updates each time it builds.
				EOF
				meta_set "failure_reason" "runtime-txt::not-supported"
				exit 1
			fi

			output::warning <<-EOF
				Warning: The runtime.txt file is deprecated.

				The runtime.txt file is deprecated since it has been replaced
				by the more widely supported .python-version file:
				https://devcenter.heroku.com/changelog-items/3141

				Please switch to using a .python-version file instead.

				${instructions}

				In the future support for runtime.txt will be removed and
				this warning will be made an error.
			EOF
			;;
		Pipfile.lock)
			# Decide if we want to warn for this case.
			;;
		*) utils::abort_internal_error "Unhandled Python version origin: ${python_version_origin}" ;;
	esac
}

function python_version::python_version_file_instructions() {
	local python_version_origin="${1}"
	local python_major_version="${2}"

	if [[ "${python_version_origin}" == "runtime.txt" ]]; then
		cat <<-EOF
			Delete your runtime.txt file and create a new file in the
			root directory of your app named:
		EOF
	else
		cat <<-EOF
			Create a new file in the root directory of your app named:
		EOF
	fi

	cat <<-EOF
		.python-version

		Make sure to include the '.' character at the start of the
		filename. Don't add a file extension such as '.txt'.

		In the new file, specify your app's major Python version number
		only. Don't include quotes or a 'python-' prefix.

		For example, to request the latest version of Python ${python_major_version},
		update your .python-version file so it contains exactly:
		${python_major_version}

		We strongly recommend that you don't specify the Python patch
		version number, since it will pin your app to an exact Python
		version and so stop your app from receiving security updates
		each time it builds.
	EOF
}

function python_version::warn_if_deprecated_major_version() {
	local requested_major_version="${1}"
	local version_origin="${2}"

	if [[ "${requested_major_version}" == "3.9" ]]; then
		output::warning <<-EOF
			Warning: Support for Python 3.9 is ending soon!

			Python 3.9 will reach its upstream end-of-life in October 2025,
			at which point it will no longer receive security updates:
			https://devguide.python.org/versions/#supported-versions

			As such, support for Python 3.9 will be removed from this
			buildpack on 7th January 2026.

			Upgrade to a newer Python version as soon as possible, by
			changing the version in your ${version_origin} file.

			For more information, see:
			https://devcenter.heroku.com/articles/python-support#supported-python-versions
		EOF
	fi
}

function python_version::warn_if_patch_update_available() {
	local python_full_version="${1}"
	local python_major_version="${2}"
	local python_version_origin="${3}"

	local latest_known_patch_version
	latest_known_patch_version="$(python_version::resolve_python_version "${python_major_version}" "${python_version_origin}")"
	# Extract the patch version component of the version strings (ie: the '2' in '3.13.2').
	local requested_patch_number="${python_full_version##*.}"
	local latest_patch_number="${latest_known_patch_version##*.}"

	if ((requested_patch_number < latest_patch_number)); then
		output::warning <<-EOF
			Warning: A Python patch update is available!

			Your app is using Python ${python_full_version}, however, there is a newer
			patch release of Python ${python_major_version} available: ${latest_known_patch_version}

			It is important to always use the latest patch version of
			Python to keep your app secure.

			Update your ${python_version_origin} file to use the new version.

			We strongly recommend that you don't pin your app to an
			exact Python version such as ${python_full_version}, and instead only specify
			the major Python version of ${python_major_version} in your ${python_version_origin} file.
			This will allow your app to receive the latest available Python
			patch version automatically and prevent this warning.
		EOF
		meta_set "python_version_outdated" "true"
	else
		meta_set "python_version_outdated" "false"
	fi
}
