#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

POETRY_VERSION=$(utils::get_requirement_version 'poetry')

function poetry::install_poetry() {
	local cache_dir="${1}"
	local export_file="${2}"

	# We store Poetry in the build cache, since we only need it during the build.
	local poetry_root="${cache_dir}/.heroku/python-poetry"

	# We nest the venv and then symlink the `poetry` script to prevent the rest of `venv/bin/`
	# (such as entrypoint scripts from Poetry's dependencies, or the venv's activation scripts)
	# from being added to PATH and exposed to the app.
	local poetry_bin_dir="${poetry_root}/bin"
	local poetry_venv_dir="${poetry_root}/venv"

	meta_set "poetry_version" "${POETRY_VERSION}"

	# The earlier buildpack cache invalidation step will have already handled the case where the
	# Poetry version has changed, so here we only need to check that a valid Poetry install exists.
	# venvs are not relocatable, so if the cache directory were ever to change location, the cached
	# Poetry installation would stop working. To save having to track the cache location via build
	# metadata, we instead rely on the fact that relocating the venv would also break the absolute
	# path `poetry` symlink created below, and that the `-e` condition not only checks that the
	# `poetry` symlink exists, but that its target is also valid.
	# Note: Whilst the Codon cache location remains stable from build to build, for Heroku CI the
	# cache directory currently does not, so the cached Poetry will always be invalidated there.
	if [[ -e "${poetry_bin_dir}/poetry" ]]; then
		output::step "Using cached Poetry ${POETRY_VERSION}"
	else
		output::step "Installing Poetry ${POETRY_VERSION}"

		# The Poetry directory will already exist in the relocated cache case mentioned above.
		rm -rf "${poetry_root}"
		mkdir -p "${poetry_root}"

		# We can't use the pip wheel bundled within Python's standard library to install Poetry
		# (which would allow us to use `--without-pip` here to skip the pip install), since it
		# requires using the `--python` option, which was only added in pip v22.3. And whilst
		# all major Python versions we support now bundled a newer pip than that, some apps
		# are still using outdated patch releases of those Python versions, whose bundled pip
		# can be older (for example Python 3.9.0 ships with pip v20.2.1). Once Python 3.10 EOLs
		# we can switch back to the previous approach since Python 3.11.0 ships with pip v22.3.
		# Changing the working directory away from the build dir is required to work around an
		# `ensurepip` bug in older Python versions, where it doesn't run Python in isolated mode:
		# https://github.com/heroku/heroku-buildpack-python/issues/1697
		if ! (cd "${poetry_root}" && python -m venv "${poetry_venv_dir}"); then
			output::error <<-EOF
				Internal Error: Unable to create virtual environment for Poetry.

				The 'python -m venv' command to create a virtual environment did
				not exit successfully.

				See the log output above for more information.
			EOF
			meta_set "failure_reason" "create-venv::poetry"
			exit 1
		fi

		if ! {
			"${poetry_venv_dir}/bin/pip" \
				install \
				--disable-pip-version-check \
				--no-cache-dir \
				--no-input \
				--quiet \
				"poetry==${POETRY_VERSION}"
		}; then
			output::error <<-EOF
				Error: Unable to install Poetry.

				Try building again to see if the error resolves itself.

				If that does not help, check the status of PyPI (the Python
				package repository service), here:
				https://status.python.org
			EOF
			meta_set "failure_reason" "install-package-manager::poetry"
			exit 1
		fi

		mkdir -p "${poetry_bin_dir}"
		# NB: This symlink must not use `--relative`, since we want the symlink to break if the cache
		# (and thus venv) were ever relocated - so that it triggers a reinstall (see above).
		ln --symbolic --no-target-directory "${poetry_venv_dir}/bin/poetry" "${poetry_bin_dir}/poetry"
	fi

	export PATH="${poetry_bin_dir}:${PATH}"
	echo "export PATH=\"${poetry_bin_dir}:\${PATH}\"" >>"${export_file}"
	# Force Poetry to manage the system Python site-packages instead of using venvs.
	export POETRY_VIRTUALENVS_CREATE="false"
	echo 'export POETRY_VIRTUALENVS_CREATE="false"' >>"${export_file}"
}

# Note: We cache site-packages since:
# - It results in faster builds than only caching Poetry's download/wheel cache.
# - It's safe to do so, since `poetry sync` fully manages the environment (including
#   e.g. uninstalling packages when they are removed from the lockfile).
#
# With site-packages cached there is no need to persist Poetry's download/wheel cache in the build
# cache, so we let Poetry write it to the home directory where it will be discarded at the end of
# the build. We don't use `--no-cache` since the cache still offers benefits (such as avoiding
# repeat downloads of PEP-517/518 build requirements).
function poetry::install_dependencies() {
	local poetry_install_command=(
		poetry
		sync
	)

	# On Heroku CI, all default Poetry dependency groups are installed (i.e. all groups minus those
	# marked as `optional = true`). Otherwise, only the 'main' Poetry dependency group is installed.
	if [[ ! -v INSTALL_TEST ]]; then
		poetry_install_command+=(--only main)
	fi

	# We only display the most relevant command args here, to improve the signal to noise ratio.
	output::step "Installing dependencies using '${poetry_install_command[*]}'"

	# `--compile`: Compiles Python bytecode, to improve app boot times (pip does this by default).
	# `--no-ansi`: Whilst we'd prefer to enable colour if possible, Poetry also emits ANSI escape
	#              codes for redrawing lines, which renders badly in persisted build logs.
	# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
	if ! {
		"${poetry_install_command[@]}" \
			--compile \
			--no-ansi \
			--no-interaction \
			|& tee "${WARNINGS_LOG:?}" \
			|& sed --unbuffered --expression '/Skipping virtualenv creation/d' \
			|& output::indent
	}; then
		# TODO: Overhaul warnings and combine them with error handling.
		show-warnings

		output::error <<-EOF
			Error: Unable to install dependencies using Poetry.

			See the log output above for more information.
		EOF
		meta_set "failure_reason" "install-dependencies::poetry"
		exit 1
	fi
}
