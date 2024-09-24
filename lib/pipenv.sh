#!/usr/bin/env bash

# export CLINT_FORCE_COLOR=1
# export PIPENV_FORCE_COLOR=1

function pipenv::install_pipenv() {
	# TODO: Either make this `local` or move elsewhere as part of the cache invalidation refactoring.
	PIPENV_VERSION=$(get_requirement_version 'pipenv')
	meta_set "pipenv_version" "${PIPENV_VERSION}"

	puts-step "Installing Pipenv ${PIPENV_VERSION}"

	# TODO: Install Pipenv into a venv so it isn't leaked into the app environment.
	# TODO: Explore viability of making Pipenv only be available during the build, to reduce slug size.
	/app/.heroku/python/bin/pip install --quiet --disable-pip-version-check --no-cache-dir "pipenv==${PIPENV_VERSION}"
}

# Previous versions of the buildpack used to cache the checksum of the lockfile to allow
# for skipping pipenv install if the lockfile was unchanged. However, this is not always safe
# to do (the lockfile can refer to dependencies that can change independently of the lockfile,
# for example, when using a local non-editable file dependency), so we no longer ever skip
# install, and instead defer to pipenv to determine whether install is actually a no-op.
function pipenv::install_dependencies() {
	# Make select pip config vars set on the Heroku app available to the pip used by Pipenv.
	# TODO: Expose all config vars (after suitable checks are added for unsafe env vars).
	#
	# PIP_EXTRA_INDEX_URL allows for an alternate pypi URL to be used.
	if [[ -r "${ENV_DIR}/PIP_EXTRA_INDEX_URL" ]]; then
		PIP_EXTRA_INDEX_URL="$(cat "${ENV_DIR}/PIP_EXTRA_INDEX_URL")"
		export PIP_EXTRA_INDEX_URL
	fi

	# Install the test dependencies, for CI.
	# TODO: This is currently inconsistent with the non-test path, since it assumes (but doesn't check for) a lockfile.
	if [[ -n "${INSTALL_TEST}" ]]; then
		puts-step "Installing test dependencies with Pipenv"
		/app/.heroku/python/bin/pipenv install --dev --system --deploy --extra-pip-args='--src=/app/.heroku/src' 2>&1 | cleanup | indent

	# Install the dependencies.
	elif [[ ! -f Pipfile.lock ]]; then
		puts-step "Installing dependencies with Pipenv"
		/app/.heroku/python/bin/pipenv install --system --skip-lock --extra-pip-args='--src=/app/.heroku/src' 2>&1 | indent

	else
		puts-step "Installing dependencies with Pipenv"
		/app/.heroku/python/bin/pipenv install --system --deploy --extra-pip-args='--src=/app/.heroku/src' 2>&1 | indent
	fi
}
