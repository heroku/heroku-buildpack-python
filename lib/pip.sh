#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

function pip::install_pip_setuptools_wheel() {
	# We use the pip wheel bundled within Python's standard library to install our chosen
	# pip version, since it's faster than `ensurepip` followed by an upgrade in place.
	local bundled_pip_module_path="${1}"
	local python_major_version="${2}"

	# TODO: Either make these `local` or move elsewhere as part of the cache invalidation refactoring.
	PIP_VERSION=$(get_requirement_version 'pip')
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
		SETUPTOOLS_VERSION=$(get_requirement_version 'setuptools')
		WHEEL_VERSION=$(get_requirement_version 'wheel')
		meta_set "setuptools_version" "${SETUPTOOLS_VERSION}"
		meta_set "wheel_version" "${WHEEL_VERSION}"

		packages_to_install+=(
			"setuptools==${SETUPTOOLS_VERSION}"
			"wheel==${WHEEL_VERSION}"
		)
		packages_display_text+=", setuptools ${SETUPTOOLS_VERSION} and wheel ${WHEEL_VERSION}"
	fi

	output::step "Installing ${packages_display_text}"

	/app/.heroku/python/bin/python "${bundled_pip_module_path}" install --quiet --disable-pip-version-check --no-cache-dir \
		"${packages_to_install[@]}"
}

function pip::install_dependencies() {
	output::step "Installing requirements with pip"

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

	# TODO: Deprecate/sunset this missing requirements file fallback.
	if [[ -f setup.py && ! -f requirements.txt ]]; then
		args=(--editable .)
	else
		args=(-r requirements.txt)
	fi

	set +e
	# shellcheck disable=SC2154 # TODO: Env var is referenced but not assigned.
	/app/.heroku/python/bin/pip install "${args[@]}" --exists-action=w --src='/app/.heroku/src' --disable-pip-version-check --no-cache-dir --progress-bar off 2>&1 | tee "${WARNINGS_LOG}" | cleanup | output::indent
	local PIP_STATUS="${PIPESTATUS[0]}"
	set -e

	show-warnings

	if [[ ! ${PIP_STATUS} -eq 0 ]]; then
		meta_set "failure_reason" "pip-install"
		return 1
	fi

	# Install test dependencies, for Heroku CI.
	if [[ "${INSTALL_TEST:-0}" == "1" ]]; then
		if [[ -f requirements-test.txt ]]; then
			output::step "Installing test dependencies..."
			/app/.heroku/python/bin/pip install -r requirements-test.txt --exists-action=w --src='/app/.heroku/src' --disable-pip-version-check --no-cache-dir 2>&1 | cleanup | output::indent
		fi
	fi
}
