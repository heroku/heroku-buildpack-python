#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

POETRY_VERSION=$(utils::get_requirement_version 'poetry')

function poetry::install_poetry() {
	local python_home="${1}"
	local cache_dir="${2}"
	local export_file="${3}"

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

		python -m venv --without-pip "${poetry_venv_dir}"

		# We use the pip wheel bundled within Python's standard library to install Poetry.
		# Whilst Poetry does still require pip for some tasks (such as package uninstalls),
		# it bundles its own copy for use as a fallback. As such we don't need to install pip
		# into the Poetry venv (and in fact, Poetry wouldn't use this install anyway, since
		# it only finds an external pip if it exists in the target venv).
		local bundled_pip_module_path
		bundled_pip_module_path="$(utils::bundled_pip_module_path "${python_home}")"

		if ! {
			python "${bundled_pip_module_path}" \
				--python "${poetry_venv_dir}" \
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
			meta_set "failure_reason" "install-poetry"
			return 1
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
# - It's safe to do so, since `poetry install --sync` fully manages the environment
#   (including e.g. uninstalling packages when they are removed from the lockfile).
#
# With site-packages cached there is no need to persist Poetry's download/wheel cache in the build
# cache, so we let Poetry write it to the home directory where it will be discarded at the end of
# the build. We don't use `--no-cache` since the cache still offers benefits (such as avoiding
# repeat downloads of PEP-517/518 build requirements).
function poetry::install_dependencies() {
	local poetry_install_command=(
		poetry
		install
		--sync
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
		"${poetry_install_command[@]}" --compile --no-ansi --no-interaction \
			|& tee "${WARNINGS_LOG:?}" \
			|& grep --invert-match 'Skipping virtualenv creation' \
			|& output::indent
	}; then
		show-warnings

		output::error <<-EOF
			Error: Unable to install dependencies using Poetry.

			See the log output above for more information.
		EOF
		meta_set "failure_reason" "install-dependencies::poetry"
		return 1
	fi
}
