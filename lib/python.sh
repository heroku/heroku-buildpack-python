#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

DEFAULT_S3_BASE_URL="https://heroku-buildpack-python.s3.us-east-1.amazonaws.com"

function python::install() {
	local build_dir="${1}"
	local stack="${2}"
	local python_full_version="${3}"
	local python_major_version="${4}"
	local python_version_origin="${5}"

	local install_python_start_time
	install_python_start_time=$(nowms)
	local install_dir="${build_dir}/.heroku/python"

	if [[ -f "${install_dir}/bin/python" ]]; then
		output::step "Using cached install of Python ${python_full_version}"
	else
		output::step "Installing Python ${python_full_version}"

		mkdir -p "${install_dir}"

		# Note: This can't be used via app config vars, since it doesn't reference the value from ENV_DIR.
		# TODO: Remove this for parity with the Python CNB, if metrics show it to be unused on Heroku.
		if [[ -v BUILDPACK_S3_BASE_URL ]]; then
			local s3_base_url="${BUILDPACK_S3_BASE_URL}"
			meta_set "custom_s3_base_url" "true"
		else
			local s3_base_url="${DEFAULT_S3_BASE_URL}"
		fi

		# Calculating the Ubuntu version from the stack name saves having to shell out to `lsb_release`.
		local ubuntu_version="${stack/heroku-/}.04"
		local arch
		arch=$(dpkg --print-architecture)
		# e.g.: https://heroku-buildpack-python.s3.us-east-1.amazonaws.com/python-3.13.0-ubuntu-24.04-amd64.tar.zst
		local python_url="${s3_base_url}/python-${python_full_version}-ubuntu-${ubuntu_version}-${arch}.tar.zst"

		local error_log
		error_log=$(mktemp)

		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! {
			{
				# We set max-time for improved UX/metrics for hanging downloads compared to relying
				# on the build system timeout. The Python archives are only ~10 MB so take < 1s to
				# download on Heroku's build system, however, we use much higher timeouts so that
				# the buildpack works in non-Heroku environments that may be far from `us-east-1`
				# or have a slower connection. We don't use `--speed-limit` since it gives worse
				# error messages when used with retries and piping to tar.
				curl \
					--connect-timeout 10 \
					--fail \
					--max-time 120 \
					--retry-max-time 120 \
					--retry 3 \
					--retry-connrefused \
					--show-error \
					--silent \
					"${python_url}" \
					| tar \
						--directory "${install_dir}" \
						--extract \
						--zstd
			} \
				|& tee "${error_log}" \
				|& output::indent
		}; then
			local latest_known_patch_version
			latest_known_patch_version="$(python_version::resolve_python_version "${python_major_version}" "${python_version_origin}")"
			# Ideally we would inspect the HTTP status code directly instead of grepping, however:
			# 1. We want to pipe to tar (since it's faster than performing the download and
			#    decompression/extraction as separate steps), so can't write to stdout.
			# 2. We want to display the original stderr to the user, so can't write to stderr.
			# 3. Curl's `--write-out` feature only supports outputting to a file (as opposed to
			#    stdout/stderr) as of curl v8.3.0, which is newer than the curl on Heroku-22.
			# This has an integration test run against all stacks, which will mean we will know
			# if future versions of curl change the error message string.
			#
			# We have to check for HTTP 403s too, since S3 will return a 403 instead of a 404 for
			# missing files, if the S3 bucket does not have public list permissions enabled.
			if [[ "${python_full_version}" != "${latest_known_patch_version}" ]] && grep --quiet "The requested URL returned error: 40[34]" "${error_log}"; then
				output::error <<-EOF
					Error: The requested Python version isn't available.

					Your app's ${python_version_origin} file specifies a Python version
					of ${python_full_version}, however, we couldn't find that version on S3.

					Check that this Python version has been released upstream,
					and that the Python buildpack has added support for it:
					https://www.python.org/downloads/
					https://github.com/heroku/heroku-buildpack-python/blob/main/CHANGELOG.md

					If it has, make sure that you are using the latest version
					of this buildpack, and haven't pinned to an older release:
					https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
					https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

					We also strongly recommend that you don't pin your app to an
					exact Python version such as ${python_full_version}, and instead only specify
					the major Python version of ${python_major_version} in your ${python_version_origin} file.
					This will allow your app to receive the latest available Python
					patch version automatically, and prevent this type of error.
				EOF
				meta_set "failure_reason" "python-version::unknown-patch"
				meta_set "failure_detail" "${python_full_version}"
			else
				output::error <<-EOF
					Error: Unable to download/install Python.

					An error occurred while downloading/installing the Python
					runtime archive from:
					${python_url}

					In some cases, this happens due to a temporary issue with
					the network connection or server.

					First, make sure that you are using the latest version
					of this buildpack, and haven't pinned to an older release:
					https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
					https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references

					Then try building again to see if the error resolves itself.
				EOF
				meta_set "failure_reason" "install-python"
				# e.g.: 'curl: (6) Could not resolve host: heroku-buildpack-python.s3.us-east-1.amazonaws.com'
				meta_set "failure_detail" "$(head --lines=1 "${error_log}" || true)"
			fi

			exit 1
		fi
	fi

	meta_time "python_install_duration" "${install_python_start_time}"
}
