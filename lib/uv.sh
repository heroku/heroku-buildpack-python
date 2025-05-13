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
			# We set max-time for improved UX for hanging downloads compared to relying on the build system
			# timeout. The uv archive is only ~15 MB so takes < 1s to download on Heroku's build system,
			# however, we use much higher timeouts so that the buildpack works in non-Heroku or local
			# environments that may have a slower connection. We don't use `--speed-limit` since it gives
			# worse error messages when used with retries and piping to tar.
			# We have to use `--strip-components` since the archive contents are nested under a subdirectory.
			curl \
				--connect-timeout 10 \
				--fail \
				--location \
				--max-time 120 \
				--retry-max-time 120 \
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
					--strip-components 1
		}; then
			output::error <<-EOF
				Error: Unable to install uv.

				Failed to download/install uv from GitHub:
				${uv_url}

				In some cases, this happens due to a temporary issue with
				the network connection or GitHub's API/CDN.

				Try building again to see if the error resolves itself.

				If that doesn't help, check the status of GitHub here:
				https://www.githubstatus.com
			EOF
			meta_set "failure_reason" "install-package-manager::uv"
			exit 1
		fi
	fi

	export PATH="${uv_dir}:${PATH}"
	# Make uv manage the system site-packages of our Python install instead of creating a venv.
	export UV_PROJECT_ENVIRONMENT="${python_home}"
	# Prevent uv from downloading/using its own Python installation.
	export UV_NO_MANAGED_PYTHON="1"
	export UV_PYTHON_DOWNLOADS="never"

	# Set the same env vars in the environment used by later buildpacks.
	cat >>"${export_file}" <<-EOF
		export PATH="${uv_dir}:\${PATH}"
		export UV_PROJECT_ENVIRONMENT="${python_home}"
		export UV_NO_MANAGED_PYTHON="1"
		export UV_PYTHON_DOWNLOADS="never"
	EOF

	# As a performance optimisation, uv attempts to use hardlinks instead of copying files from its
	# download cache into site-packages, and will emit a warning if it has to fall back to copying.
	# By default uv stores its cache under `$HOME/.cache`, and for standard Heroku builds `$HOME` is
	# `/app`, which is on a different filesystem mount to the build directory (which is under `/tmp`),
	# meaning hardlinks can't be used. To avoid this we tell uv to store its cache in `/tmp`.
	# However, we have to do so conditionally, since for Heroku CI both the home directory and
	# the build directory are `/app`, where hardlinks already work and changing the cache to `/tmp`
	# would instead break them.
	#
	# There's also a third case, a non-CI build where the app has the undocumented `build-in-app-dir`
	# labs enabled, however, for that scenario the build directory is `/app` and the home directory
	# is `/tmp`, so we can't use hardlinks unless we wrote the cache to the build directory and
	# manually deleted it after. For now we ignore this case since not many apps use that labs,
	# and uv will still work after falling back to copying files (with a warning).
	#
	# Longer term, ideally uv's `--no-cache` option would co-locate the temporary cache it writes
	# alongside site-packages (see https://github.com/astral-sh/uv/issues/11385), and we could use
	# that everywhere since we don't actually need to persist uv's cache (see below).
	# shellcheck disable=SC2312 # Invoke this command separately to avoid masking its return value.
	if [[ "$(realpath "${python_home}")" =~ ^/tmp/ ]]; then
		export UV_CACHE_DIR='/tmp/uv-cache'
		echo 'export UV_CACHE_DIR="/tmp/uv-cache"' >>"${export_file}"
	fi
}

# Note: We cache site-packages since:
# - It results in faster builds than only caching uv's download/wheel cache.
# - It improves the UX of the build log, since uv will display which packages were
#   added/removed since the last successful build.
# - It's safe to do so, since `uv sync` fully manages the environment (including
#   e.g. uninstalling packages when they are removed from the lockfile).
#
# With site-packages cached there is no need to persist uv's cache in the build cache, so we let
# uv write it to the home directory (or `UV_CACHE_DIR`, see above) where it will be discarded at
# the end of the build. We don't use `--no-cache` since all it does is make uv switch to a temporary
# cache directory under `/tmp`, which would mean hardlinks can't be used for Heroku CI (see above).
function uv::install_dependencies() {
	local uv_install_command=(
		uv
		sync
		--locked
	)

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
		"${uv_install_command[@]}" \
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
}
