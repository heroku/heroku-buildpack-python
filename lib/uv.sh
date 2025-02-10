#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

UV_VERSION=$(utils::get_requirement_version 'uv')

function uv::install_uv() {
	local cache_dir="${1}"
	local export_file="${2}"
	local python_home="${3}"

	# We store uv in the build cache, since we only need it during the build.
	local uv_dir="${cache_dir}/.heroku/python-uv"

	meta_set "uv_version" "${UV_VERSION}"

	# The earlier buildpack cache invalidation step will have already handled the case where
	# the uv version has changed, so here we only need to check whether the uv binary exists.
	if [[ -f "${uv_dir}/uv" ]]; then
		output::step "Using cached uv ${UV_VERSION}"
	else
		output::step "Installing uv ${UV_VERSION}"
		mkdir -p "${uv_dir}"

		local gnu_arch
		# eg: `x86_64` or `aarch64`.
		gnu_arch=$(arch)
		local uv_url="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${gnu_arch}-unknown-linux-gnu.tar.gz"

		if ! {
			curl \
				--connect-timeout 10 \
				--fail \
				--location \
				--retry 3 \
				--retry-connrefused \
				--show-error \
				--silent \
				"${uv_url}" \
				| tar \
					--directory "${uv_dir}" \
					--extract \
					--gzip \
					--no-anchored \
					--strip-components 1 \
					uv
		}; then
			output::error <<-EOF
				Error: Unable to install uv.

				In some cases, this happens due to an unstable network connection.
				Try building again to see if the error resolves itself.
			EOF
			meta_set "failure_reason" "install-package-manager::uv"
			exit 1
		fi
	fi

	export PATH="${uv_dir}:${PATH}"
	# Make uv manage the system site-packages of our Python install instead of creating a venv.
	export UV_PROJECT_ENVIRONMENT="${python_home}"
	# Force uv to use our Python install instead of performing discovery (which could potentially
	# use distro Python if the app doesn't have a .python-version and `requires-python` matches
	# the distro Python version). However, setting this option makes the error message worse for
	# apps that have a `.python-version` with a version that conflicts with `requires-python`.
	# TODO: Consider only setting `UV_PYTHON` when the version origin wasn't .python-version,
	# or make .python-version mandatory when using uv and stop setting `UV_PYTHON` entirely.
	export UV_PYTHON="${python_home}"
	# Prevent uv from downloading/using its own Python installation.
	export UV_PYTHON_DOWNLOADS="never"
	export UV_PYTHON_PREFERENCE="only-system"

	# TODO: Open upstream issue about improving default behaviour here.
	# (It's not currently possible to say "hardlink or reflink", only one or
	# the other, which doesn't work well given Kodon vs Heroku CI filesystems.)
	# export UV_LINK_MODE="copy"

	# Set the same env vars in the environment used by later buildpacks.
	cat >>"${export_file}" <<-EOF
		export PATH="${uv_dir}:\${PATH}"
		export UV_LINK_MODE="copy"
		export UV_PROJECT_ENVIRONMENT="${python_home}"
		export UV_PYTHON="${python_home}"
		export UV_PYTHON_DOWNLOADS="never"
		export UV_PYTHON_PREFERENCE="only-system"
	EOF
}

# Note: We cache site-packages since:
# - It results in faster builds than only caching uv's download/wheel cache.
# - It improves the UX of the build log, since uv will display which packages were
#   added/removed since the last successful build.
# - It's safe to do so, since `uv sync` fully manages the environment (including
#   e.g. uninstalling packages when they are removed from the lockfile).
#
# With site-packages cached there is no need to persist uv's cache in the build cache, so we let
# uv write it to the home directory where it will be discarded at the end of the build. We don't
# use `--no-cache` since all it does is make uv switch to a temporary cache which uv will delete
# after the command has run - which would both be a waste of I/O and also mean if users happen to
# manually run any uv commands later in the build they will have a cold cache.
function uv::install_dependencies() {
	local uv_install_command=(
		uv
		sync
		--locked
		--no-cache
	)

	# --cache-dir /tmp/uv-cache
	# --no-cache

	export UV_LINK_MODE="copy"

	echo "Link mode is: ${UV_LINK_MODE:-unset}"
	echo "Command: ${uv_install_command[*]}"

	# Unless we're building on Heroku CI, we omit the default dependency groups (such as `dev`):
	# https://docs.astral.sh/uv/concepts/projects/dependencies/#dependency-groups
	if [[ ! -v INSTALL_TEST ]]; then
		uv_install_command+=(--no-default-groups)
	fi

	# We only display the most relevant command args here, to improve the signal to noise ratio.
	output::step "Installing dependencies using '${uv_install_command[*]}'"

	# TODO: Expose app config vars to the install command as part of doing so for all package managers.
	# `--compile-bytecode`: Improves app boot times (pip does this by default).
	# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
	if ! {
		time "${uv_install_command[@]}" \
			--color always \
			--compile-bytecode \
			--no-progress \
			|& tee "${WARNINGS_LOG:?}" \
			|& output::indent
	}; then
		# TODO: Overhaul warnings and combine them with error handling (for all package managers).
		show-warnings

		output::error <<-EOF
			Error: Unable to install dependencies using uv.

			See the log output above for more information.
		EOF
		meta_set "failure_reason" "install-dependencies::uv"
		exit 1
	fi

	exit 1
}
