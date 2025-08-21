#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

POETRY_VERSION=$(utils::get_requirement_version 'poetry')

function poetry::install_poetry() {
	local python_home="${1}"
	local python_major_version="${2}"
	local cache_dir="${3}"
	local export_file="${4}"

	# We store Poetry in the build cache, since we only need it during the build.
	local poetry_root="${cache_dir}/.heroku/python-poetry"

	# We nest the venv and then symlink the `poetry` script to prevent the rest of `venv/bin/`
	# (such as entrypoint scripts from Poetry's dependencies, or the venv's activation scripts)
	# from being added to PATH and exposed to the app.
	local poetry_bin_dir="${poetry_root}/bin"
	local poetry_venv_dir="${poetry_root}/venv"

	build_data::set_string "poetry_version" "${POETRY_VERSION}"

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

		# We use the pip wheel bundled within Python's standard library to install Poetry.
		# Whilst Poetry does still require pip for some tasks (such as package uninstalls),
		# it bundles its own copy for use as a fallback. As such we don't need to install pip
		# into the Poetry venv (and in fact, Poetry wouldn't use this install anyway, since
		# it only finds an external pip if it exists in the target venv).
		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! python -m venv --without-pip "${poetry_venv_dir}" |& output::indent; then
			output::error <<-EOF
				Internal Error: Unable to create virtual environment for Poetry.

				The 'python -m venv' command to create a virtual environment did
				not exit successfully.

				See the log output above for more information.
			EOF
			build_data::set_string "failure_reason" "create-venv::poetry"
			exit 1
		fi

		local bundled_pip_module_path
		bundled_pip_module_path="$(utils::bundled_pip_module_path "${python_home}" "${python_major_version}")"

		# We must call the venv Python directly here, rather than relying on pip's `--python`
		# option, since `--python` was only added in pip v22.3, so isn't supported by the older
		# pip versions bundled with Python 3.9/3.10.
		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! {
			"${poetry_venv_dir}/bin/python" "${bundled_pip_module_path}" \
				install \
				--disable-pip-version-check \
				--no-cache-dir \
				--no-input \
				--quiet \
				"poetry==${POETRY_VERSION}" \
				|& output::indent
		}; then
			output::error <<-EOF
				Error: Unable to install Poetry.

				In some cases, this happens due to a temporary issue with
				the network connection or Python Package Index (PyPI).

				Try building again to see if the error resolves itself.

				If that doesn't help, check the status of PyPI here:
				https://status.python.org
			EOF
			build_data::set_string "failure_reason" "install-package-manager::poetry"
			exit 1
		fi

		mkdir -p "${poetry_bin_dir}"
		# NB: This symlink must not use `--relative`, since we want the symlink to break if the cache
		# (and thus venv) were ever relocated - so that it triggers a reinstall (see above).
		ln --symbolic --no-target-directory "${poetry_venv_dir}/bin/poetry" "${poetry_bin_dir}/poetry"
	fi

	export PATH="${poetry_bin_dir}:${PATH}"
	# Force Poetry to manage the system Python site-packages instead of using venvs.
	export POETRY_VIRTUALENVS_CREATE="false"
	# Force Poetry to use our Python rather than scanning PATH (which might pick system Python).
	# Though this currently doesn't work as documented: https://github.com/python-poetry/poetry/issues/10226
	export POETRY_VIRTUALENVS_USE_POETRY_PYTHON="true"

	# Set the same env vars in the environment used by later buildpacks.
	cat >>"${export_file}" <<-EOF
		export PATH="${poetry_bin_dir}:\${PATH}"
		export POETRY_VIRTUALENVS_CREATE="false"
		export POETRY_VIRTUALENVS_USE_POETRY_PYTHON="true"
	EOF
}

# Note: We cache site-packages since:
# - It results in faster builds than only caching Poetry's download/wheel cache.
# - It improves the UX of the build log, since Poetry will display which packages were
#   added/removed since the last successful build.
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
		build_data::set_string "failure_reason" "install-dependencies::poetry"
		exit 1
	fi
}
