#!/usr/bin/env bash

function pip::install_pip_setuptools_wheel() {
	local python_home="${1}"

	# We use the pip wheel bundled within Python's standard library to install our chosen
	# pip version, since it's faster than `ensurepip` followed by an upgrade in place.
	local bundled_pip_module_path
	bundled_pip_module_path="$(utils::bundled_pip_module_path "${python_home}")"

	# TODO: Either make these `local` or move elsewhere as part of the cache invalidation refactoring.
	PIP_VERSION=$(utils::get_requirement_version 'pip')
	SETUPTOOLS_VERSION=$(utils::get_requirement_version 'setuptools')
	WHEEL_VERSION=$(utils::get_requirement_version 'wheel')
	meta_set "pip_version" "${PIP_VERSION}"
	meta_set "setuptools_version" "${SETUPTOOLS_VERSION}"
	meta_set "wheel_version" "${WHEEL_VERSION}"

	puts-step "Installing pip ${PIP_VERSION}, setuptools ${SETUPTOOLS_VERSION} and wheel ${WHEEL_VERSION}"

	if ! {
		python "${bundled_pip_module_path}" \
			install \
			--disable-pip-version-check \
			--no-cache-dir \
			--no-input \
			--quiet \
			"pip==${PIP_VERSION}" \
			"setuptools==${SETUPTOOLS_VERSION}" \
			"wheel==${WHEEL_VERSION}"
	}; then
		display_error <<-EOF
			Error: Unable to install pip.

			Try building again to see if the error resolves itself.

			If that does not help, check the status of PyPI (the Python
			package repository service), here:
			https://status.python.org
		EOF
		meta_set "failure_reason" "install-pip"
		return 1
	fi
}

function pip::install_dependencies() {
	puts-step "Installing requirements with pip"

	# Make select pip config vars set on the Heroku app available to pip.
	# TODO: Expose all config vars (after suitable checks are added for unsafe env vars)
	# to allow for the env var interpolation feature of requirements files to work.
	#
	# PIP_EXTRA_INDEX_URL allows for an alternate pypi URL to be used.
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
	pip install "${args[@]}" --exists-action=w --src='/app/.heroku/src' --disable-pip-version-check --no-cache-dir --progress-bar off 2>&1 | tee "$WARNINGS_LOG" | indent
	local PIP_STATUS="${PIPESTATUS[0]}"
	set -e

	# TODO: Overhaul warnings and combine them with error handling.
	show-warnings

	if [[ ! ${PIP_STATUS} -eq 0 ]]; then
		# TODO: Add missing error message here.

		meta_set "failure_reason" "install-dependencies"
		return 1
	fi

	# Install test dependencies, for Heroku CI.
	if [[ "${INSTALL_TEST:-0}" == "1" ]]; then
		if [[ -f requirements-test.txt ]]; then
			puts-step "Installing test dependencies..."
			# TODO: Add missing error handling here.
			pip install -r requirements-test.txt --exists-action=w --src='/app/.heroku/src' --disable-pip-version-check --no-cache-dir 2>&1 | cleanup | indent
		fi
	fi
}
