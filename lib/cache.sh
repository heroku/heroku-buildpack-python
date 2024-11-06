#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Read the full Python version of the Python install in the cache, or the empty string
# if the cache is empty or doesn't contain a Python version metadata file.
function cache::cached_python_version() {
	local cache_dir="${1}"

	if [[ -f "${cache_dir}/.heroku/python-version" ]]; then
		local version
		version="$(cat "${cache_dir}/.heroku/python-version")"
		# For historical reasons the version has always been stored as `python-X.Y.Z`,
		# so we have to remove the `python-` prefix.
		echo "${version#python-}"
	fi
}

# Validates and restores the contents of the build cache if appropriate.
# The cache is discarded if any of the following have changed:
# - Stack
# - Python version
# - Package manager
# - Package manager version
# - requirements.txt contents (pip only)
function cache::restore() {
	local build_dir="${1}"
	local cache_dir="${2}"
	local stack="${3}"
	local cached_python_version="${4}"
	local python_full_version="${5}"
	local package_manager="${6}"

	if [[ ! -e "${cache_dir}/.heroku/python" ]]; then
		meta_set "cache_status" "empty"
		return 0
	fi

	local cache_restore_start_time
	cache_restore_start_time=$(nowms)
	local cache_invalidation_reasons=()

	local cached_stack
	cached_stack="$(cat "${cache_dir}/.heroku/python-stack" || true)"
	if [[ "${cached_stack}" != "${stack}" ]]; then
		cache_invalidation_reasons+=("The stack has changed from ${cached_stack:-"unknown"} to ${stack}")
	fi

	if [[ "${cached_python_version}" != "${python_full_version}" ]]; then
		cache_invalidation_reasons+=("The Python version has changed from ${cached_python_version:-"unknown"} to ${python_full_version}")
	fi

	# The metadata store only exists in caches created in v252+ of the buildpack (released 2024-06-17),
	# so here and below we have to handle the case where `meta_prev_get` returns the empty string.
	local cached_package_manager
	cached_package_manager="$(meta_prev_get "package_manager")"
	if [[ -z "${cached_package_manager}" ]]; then
		# Using `compgen` since `[[ -d ... ]]` doesn't work with globs.
		if compgen -G "${cache_dir}/.heroku/python/lib/python*/site-packages/pipenv" >/dev/null; then
			cached_package_manager="pipenv"
		elif compgen -G "${cache_dir}/.heroku/python/lib/python*/site-packages/pip" >/dev/null; then
			cached_package_manager="pip"
		fi
	fi

	if [[ "${cached_package_manager}" != "${package_manager}" ]]; then
		cache_invalidation_reasons+=("The package manager has changed from ${cached_package_manager:-"unknown"} to ${package_manager}")
	else
		case "${package_manager}" in
			pip)
				local cached_pip_version
				cached_pip_version="$(meta_prev_get "pip_version")"
				# Handle caches written by buildpack versions older than v252 (see above).
				if [[ -z "${cached_pip_version}" ]]; then
					# Whilst we don't know the old version, we know the pip version has likely
					# changed since the last build, and would rather err on the side of caution.
					# (The pip version was last updated in v246, but will be updated again soon.)
					cache_invalidation_reasons+=("The pip version has changed")
				elif [[ "${cached_pip_version}" != "${PIP_VERSION:?}" ]]; then
					cache_invalidation_reasons+=("The pip version has changed from ${cached_pip_version} to ${PIP_VERSION}")
				fi

				# We invalidate the cache if requirements.txt changes since pip is a package installer
				# rather than a project/environment manager, and so does not deterministically manage
				# installed Python packages. For example, if a package entry in a requirements file is
				# later removed, pip will not uninstall the package. This check can be removed if we
				# ever switch to only caching pip's HTTP/wheel cache rather than site-packages.
				# TODO: Remove the `-f` check once the setup.py fallback feature is removed.
				if [[ -f "${build_dir}/requirements.txt" ]] && ! cmp --silent "${cache_dir}/.heroku/requirements.txt" "${build_dir}/requirements.txt"; then
					cache_invalidation_reasons+=("The contents of requirements.txt changed")
				fi
				;;
			pipenv)
				local cached_pipenv_version
				cached_pipenv_version="$(meta_prev_get "pipenv_version")"
				# Handle caches written by buildpack versions older than v252 (see above).
				if [[ -z "${cached_pipenv_version}" ]]; then
					# Whilst we don't know the old version, we know the Pipenv version has definitely
					# changed since buildpack v251.
					cache_invalidation_reasons+=("The Pipenv version has changed")
				elif [[ "${cached_pipenv_version}" != "${PIPENV_VERSION:?}" ]]; then
					cache_invalidation_reasons+=("The Pipenv version has changed from ${cached_pipenv_version} to ${PIPENV_VERSION}")
				fi
				;;
			poetry)
				local cached_poetry_version
				cached_poetry_version="$(meta_prev_get "poetry_version")"
				# Poetry support was added after the metadata store, so we'll always have the version here.
				if [[ "${cached_poetry_version}" != "${POETRY_VERSION:?}" ]]; then
					cache_invalidation_reasons+=("The Poetry version has changed from ${cached_poetry_version:-"unknown"} to ${POETRY_VERSION}")
				fi
				;;
			*)
				utils::abort_internal_error "Unhandled package manager: ${package_manager}"
				;;
		esac
	fi

	if [[ -n "${cache_invalidation_reasons[*]}" ]]; then
		output::step "Discarding cache since:"
		local reason
		for reason in "${cache_invalidation_reasons[@]}"; do
			echo "       - ${reason}"
		done

		rm -rf \
			"${cache_dir}/.heroku/python" \
			"${cache_dir}/.heroku/python-poetry" \
			"${cache_dir}/.heroku/python-stack" \
			"${cache_dir}/.heroku/python-version" \
			"${cache_dir}/.heroku/src" \
			"${cache_dir}/.heroku/requirements.txt"

		meta_set "cache_status" "discarded"
	else
		output::step "Restoring cache"
		mkdir -p "${build_dir}/.heroku"

		# NB: For now this has to handle files already existing in build_dir since some apps accidentally
		# run the Python buildpack twice. TODO: Add an explicit check/error for duplicate buildpacks.
		# TODO: Investigate why errors are ignored and ideally stop doing so.
		# TODO: Compare the performance of moving the directory vs copying files.
		cp -R "${cache_dir}/.heroku/python" "${build_dir}/.heroku/" &>/dev/null || true

		# Editable VCS code repositories, used by pip/pipenv.
		if [[ -d "${cache_dir}/.heroku/src" ]]; then
			cp -R "${cache_dir}/.heroku/src" "${build_dir}/.heroku/" &>/dev/null || true
		fi

		meta_set "cache_status" "reused"
	fi

	# Remove any legacy cache contents written by older buildpack versions.
	rm -rf \
		"${cache_dir}/.heroku/python-sqlite3-version" \
		"${cache_dir}/.heroku/vendor"

	meta_time "cache_restore_duration" "${cache_restore_start_time}"
}

# Copies Python and dependencies from the build directory to the cache, for use by subsequent builds.
function cache::save() {
	local build_dir="${1}"
	local cache_dir="${2}"
	local stack="${3}"
	local python_full_version="${4}"
	local package_manager="${5}"

	local cache_save_start_time
	cache_save_start_time=$(nowms)

	mkdir -p "${cache_dir}/.heroku"

	rm -rf "${cache_dir}/.heroku/python"
	cp -R "${build_dir}/.heroku/python" "${cache_dir}/.heroku/"

	# Editable VCS code repositories, used by pip/pipenv.
	rm -rf "${cache_dir}/.heroku/src"
	if [[ -d "${build_dir}/.heroku/src" ]]; then
		# TODO: Investigate why errors are ignored and ideally stop doing so.
		cp -R "${build_dir}/.heroku/src" "${cache_dir}/.heroku/" &>/dev/null || true
	fi

	# Metadata used by subsequent builds to determine whether the cache can be reused.
	# These are written/consumed via separate files and not the metadata store for compatibility
	# with buildpack versions prior to the metadata store existing (which was only added in v252).
	echo "${stack}" >"${cache_dir}/.heroku/python-stack"
	# For historical reasons the Python version was always stored with a `python-` prefix.
	# We continue to use that format so that the file can be read by older buildpack versions.
	echo "python-${python_full_version}" >"${cache_dir}/.heroku/python-version"

	# TODO: Simplify this once multiple package manager files being found is turned into an
	# error and the setup.py fallback feature is removed.
	if [[ "${package_manager}" == "pip" && -f "${build_dir}/requirements.txt" ]]; then
		cp "${build_dir}/requirements.txt" "${cache_dir}/.heroku/"
	fi

	meta_time "cache_save_duration" "${cache_save_start_time}"
}
