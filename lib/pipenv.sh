#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

PIPENV_VERSION=$(utils::get_requirement_version 'pipenv')

function pipenv::install_pipenv() {
	local python_home="${1}"
	local python_major_version="${2}"
	local export_file="${3}"
	local profile_d_file="${4}"

	# Ideally we would only make Pipenv available during the build to reduce slug size, however,
	# the buildpack has historically not done that and so some apps are relying on it at run-time
	# (for example via `pipenv run` commands in their Procfile). As such, we have to store it in
	# the build directory, but must do so via the symlinked `/app/.heroku/python` path so the
	# venv doesn't break when the build directory is relocated to /app at run-time.
	local pipenv_root="${python_home}/pipenv"

	# We nest the venv and then symlink the `pipenv` script to prevent the rest of `venv/bin/`
	# (such as entrypoint scripts from Pipenv's dependencies, or the venv's activation scripts)
	# from being added to PATH and exposed to the app.
	local pipenv_bin_dir="${pipenv_root}/bin"
	local pipenv_venv_dir="${pipenv_root}/venv"

	build_data::set_string "pipenv_version" "${PIPENV_VERSION}"

	# The earlier buildpack cache invalidation step will have already handled the case where the
	# Pipenv version has changed, so here we only need to check that a Pipenv install exists.
	# Note: We don't need to use the `-e` trick of `install_poetry()` since we're installing into
	# a constant path, rather than the cache directory (which can change location).
	if [[ -f "${pipenv_bin_dir}/pipenv" ]]; then
		output::step "Using cached Pipenv ${PIPENV_VERSION}"
	else
		output::step "Installing Pipenv ${PIPENV_VERSION}"

		mkdir -p "${pipenv_root}"

		# We use the pip wheel bundled within Python's standard library to install Pipenv,
		# since Pipenv vendors its own pip, so doesn't need an install in the venv.
		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! python -m venv --without-pip "${pipenv_venv_dir}" |& output::indent; then
			output::error <<-EOF
				Internal Error: Unable to create virtual environment for Pipenv.

				The 'python -m venv' command to create a virtual environment did
				not exit successfully.

				See the log output above for more information.
			EOF
			build_data::set_string "failure_reason" "create-venv::pipenv"
			exit 1
		fi

		local bundled_pip_module_path
		bundled_pip_module_path="$(utils::bundled_pip_module_path "${python_home}" "${python_major_version}")"

		# We must call the venv Python directly here, rather than relying on pip's `--python`
		# option, since `--python` was only added in pip v22.3, so isn't supported by the older
		# pip versions bundled with Python 3.9/3.10.
		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! {
			"${pipenv_venv_dir}/bin/python" "${bundled_pip_module_path}" \
				install \
				--disable-pip-version-check \
				--no-cache-dir \
				--no-input \
				--quiet \
				"pipenv==${PIPENV_VERSION}" \
				|& output::indent
		}; then
			output::error <<-EOF
				Error: Unable to install Pipenv.

				In some cases, this happens due to a temporary issue with
				the network connection or Python Package Index (PyPI).

				Try building again to see if the error resolves itself.

				If that doesn't help, check the status of PyPI here:
				https://status.python.org
			EOF
			build_data::set_string "failure_reason" "install-package-manager::pipenv"
			exit 1
		fi

		mkdir -p "${pipenv_bin_dir}"
		ln --symbolic --no-target-directory "${pipenv_venv_dir}/bin/pipenv" "${pipenv_bin_dir}/pipenv"
	fi

	export PATH="${pipenv_bin_dir}:${PATH}"
	# Force Pipenv to manage the system Python site-packages instead of using venvs.
	export PIPENV_SYSTEM="1"
	# Hide Pipenv's notice about finding/using an existing virtual environment.
	export PIPENV_VERBOSITY="-1"
	# Work around a Pipenv bug when using `--system`, whereby it doesn't correctly install
	# dependencies that happen to also be a dependency of Pipenv (such as `certifi`).
	# In general Pipenv's support for its `--system` mode seems very buggy. Longer term we
	# should explore moving to venvs, however, that will need to be coordinated across all
	# package managers and also change paths for Python which could break other use cases.
	export VIRTUAL_ENV="${python_home}"

	# Set the same env vars in the environment used by later buildpacks.
	cat >>"${export_file}" <<-EOF
		export PATH="${pipenv_bin_dir}:\${PATH}"
		export PIPENV_SYSTEM="1"
		export PIPENV_VERBOSITY="-1"
		export VIRTUAL_ENV="${python_home}"
	EOF

	# And the environment used at app run-time.
	cat >>"${profile_d_file}" <<-EOF
		export PATH="${pipenv_bin_dir}:\${PATH}"
		export PIPENV_SYSTEM="1"
		export PIPENV_VERBOSITY="-1"
		export VIRTUAL_ENV="${python_home}"
	EOF
}

# Previous versions of the buildpack used to cache the checksum of the lockfile to allow
# for skipping pipenv install if the lockfile was unchanged. However, this is not always safe
# to do (the lockfile can refer to dependencies that can change independently of the lockfile,
# for example, when using a local non-editable file dependency), so we no longer ever skip
# install, and instead defer to Pipenv to determine whether install is actually a no-op.
function pipenv::install_dependencies() {
	# Make select pip config vars set on the Heroku app available to the pip used by Pipenv.
	# TODO: Expose all config vars (after suitable checks are added for unsafe env vars).
	#
	# PIP_EXTRA_INDEX_URL allows for an alternate pypi URL to be used.
	# shellcheck disable=SC2154 # TODO: Env var is referenced but not assigned.
	if [[ -r "${ENV_DIR}/PIP_EXTRA_INDEX_URL" ]]; then
		PIP_EXTRA_INDEX_URL="$(cat "${ENV_DIR}/PIP_EXTRA_INDEX_URL")"
		export PIP_EXTRA_INDEX_URL
	fi

	# Note: We can't use `pipenv sync` since it doesn't support `--deploy` and so won't abort
	# if the lockfile is out of date.
	local pipenv_install_command=(
		pipenv
		install
		--deploy
	)

	# Install test dependencies too when the buildpack is invoked via `bin/test-compile` on Heroku CI.
	if [[ -v INSTALL_TEST ]]; then
		pipenv_install_command+=(--dev)
	fi

	# We only display the most relevant command args here, to improve the signal to noise ratio.
	output::step "Installing dependencies using '${pipenv_install_command[*]}'"

	# TODO: Expose app config vars to the install command as part of doing so for all package managers.
	# `PIPENV_NOSPIN`: Disable progress spinners.
	# `PIP_SRC`: Override the editable VCS repo location from its default of inside the build directory
	#            (Pipenv uses pip internally, and doesn't offer its own config option for this).
	# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
	if ! {
		PIPENV_NOSPIN="1" PIP_SRC="/app/.heroku/python/src" \
			"${pipenv_install_command[@]}" \
			|& tee "${WARNINGS_LOG:?}" \
			|& output::indent
	}; then
		# TODO: Overhaul warnings and combine them with error handling.
		show-warnings

		output::error <<-EOF
			Error: Unable to install dependencies using Pipenv.

			See the log output above for more information.
		EOF
		build_data::set_string "failure_reason" "install-dependencies::pipenv"
		exit 1
	fi
}
