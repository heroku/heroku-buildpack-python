#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

PIP_VERSION=$(utils::get_requirement_version 'pip')
SETUPTOOLS_VERSION=$(utils::get_requirement_version 'setuptools')
WHEEL_VERSION=$(utils::get_requirement_version 'wheel')

function pip::install_pip_setuptools_wheel() {
	local python_home="${1}"
	local python_major_version="${2}"

	# We use the pip wheel bundled within Python's standard library to install our chosen
	# pip version, since it's faster than `ensurepip` followed by an upgrade in place.
	local bundled_pip_module_path
	bundled_pip_module_path="$(utils::bundled_pip_module_path "${python_home}")"

	meta_set "pip_version" "${PIP_VERSION}"

	local packages_to_install=(
		"pip==${PIP_VERSION}"
	)
	local packages_display_text="pip ${PIP_VERSION}"

	# We only install setuptools and wheel on Python 3.12 and older, since:
	# - If either is not installed, pip will automatically install them into an isolated build
	#   environment if needed when installing packages from an sdist. This means that for
	#   all packages that correctly declare their metadata, it's no longer necessary to have
	#   them installed.
	# - Most of the Python ecosystem has stopped installing them for Python 3.12+ already.
	# See the Python CNB's removal for more details: https://github.com/heroku/buildpacks-python/pull/243
	if [[ "${python_major_version}" == +(3.8|3.9|3.10|3.11|3.12) ]]; then
		meta_set "setuptools_version" "${SETUPTOOLS_VERSION}"
		meta_set "wheel_version" "${WHEEL_VERSION}"
		packages_to_install+=(
			"setuptools==${SETUPTOOLS_VERSION}"
			"wheel==${WHEEL_VERSION}"
		)
		packages_display_text+=", setuptools ${SETUPTOOLS_VERSION} and wheel ${WHEEL_VERSION}"
	fi

	# Note: We still perform this install step even if the cache was reused, since we have no guarantee
	# that the cached package versions are correct (different versions could have been specified in the
	# app's requirements.txt in the last build). The install will be a no-op if the versions match.
	output::step "Installing ${packages_display_text}"

	if ! {
		python "${bundled_pip_module_path}" \
			install \
			--disable-pip-version-check \
			--no-cache-dir \
			--no-input \
			--quiet \
			"${packages_to_install[@]}"
	}; then
		output::error <<-EOF
			Error: Unable to install pip.

			Try building again to see if the error resolves itself.

			If that does not help, check the status of PyPI (the Python
			package repository service), here:
			https://status.python.org
		EOF
		meta_set "failure_reason" "install-package-manager::pip"
		exit 1
	fi
}

function pip::install_dependencies() {
	# Make select pip config vars set on the Heroku app available to pip.
	# TODO: Expose all config vars (after suitable checks are added for unsafe env vars)
	# to allow for the env var interpolation feature of requirements files to work.
	#
	# PIP_EXTRA_INDEX_URL allows for an alternate pypi URL to be used.
	# shellcheck disable=SC2154 # TODO: Env var is referenced but not assigned.
	if [[ -r "${ENV_DIR}/PIP_EXTRA_INDEX_URL" ]]; then
		PIP_EXTRA_INDEX_URL="$(cat "${ENV_DIR}/PIP_EXTRA_INDEX_URL")"
		export PIP_EXTRA_INDEX_URL
	fi

	local pip_install_command=(
		pip
		install
	)

	# TODO: Deprecate/sunset this missing requirements file fallback.
	if [[ -f setup.py && ! -f requirements.txt ]]; then
		pip_install_command+=(--editable .)
	else
		pip_install_command+=(-r requirements.txt)
	fi

	# Install test dependencies too when the buildpack is invoked via `bin/test-compile` on Heroku CI.
	# We install both requirements files at the same time to allow pip to resolve version conflicts.
	if [[ -v INSTALL_TEST && -f requirements-test.txt ]]; then
		pip_install_command+=(-r requirements-test.txt)
	fi

	# We only display the most relevant command args here, to improve the signal to noise ratio.
	output::step "Installing dependencies using '${pip_install_command[*]}'"

	# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
	if ! {
		"${pip_install_command[@]}" \
			--disable-pip-version-check \
			--exists-action=w \
			--no-cache-dir \
			--no-input \
			--progress-bar off \
			--src='/app/.heroku/src' \
			|& tee "${WARNINGS_LOG:?}" \
			|& sed --unbuffered --expression '/Requirement already satisfied/d' \
			|& output::indent
	}; then
		# TODO: Overhaul warnings and combine them with error handling.
		show-warnings

		output::error <<-EOF
			Error: Unable to install dependencies using pip.

			See the log output above for more information.
		EOF
		meta_set "failure_reason" "install-dependencies::pip"
		exit 1
	fi
}
