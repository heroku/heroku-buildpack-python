#!/usr/bin/env bash

function checks::ensure_supported_stack() {
	local stack="${1}"

	case "${stack}" in
		heroku-22 | heroku-24)
			return 0
			;;
		cedar* | heroku-16 | heroku-18)
			# This error will only ever be seen on non-Heroku environments, since the
			# Heroku build system rejects builds using EOL stacks.
			output::error <<-EOF
				Error: The '${stack}' stack is no longer supported.

				This buildpack no longer supports the '${stack}' stack since it has
				reached its end-of-life:
				https://devcenter.heroku.com/articles/stack#stack-support-details

				Upgrade to a newer stack to continue using this buildpack.
			EOF
			meta_set "failure_reason" "stack::eol"
			meta_set "failure_detail" "${stack}"
			exit 1
			;;
		*)
			output::error <<-EOF
				Error: The '${stack}' stack isn't recognised.

				This buildpack doesn't recognise or support the '${stack}' stack.

				If '${stack}' is a valid stack, make sure that you are using the latest
				version of this buildpack and haven't pinned to an older release:
				https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
				https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
			EOF
			meta_set "failure_reason" "stack::unknown"
			meta_set "failure_detail" "${stack}"
			exit 1
			;;
	esac
}

function checks::warn_if_duplicate_python_buildpack() {
	local build_dir="${1}"

	# The check for the `PYTHONHOME` env var prevents this warning triggering in the case
	# where the Python install was committed to the Git repo (which will be handled later).
	# (The env var can only have come from the `export` file of an earlier buildpack,
	# since app provided config vars haven't been exported to the environment here.)
	if [[ -f "${build_dir}/.heroku/python/bin/python" && -v PYTHONHOME ]]; then
		output::error <<-EOF
			Error: The Python buildpack has already been run this build.

			An existing Python installation was found in the build directory
			from a buildpack run earlier in the build.

			This normally means there are duplicate Python buildpacks set
			on your app, which isn't supported, can cause errors and
			slow down builds.

			Check the buildpacks set on your app and remove any duplicate
			Python buildpack entries:
			https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
			https://devcenter.heroku.com/articles/managing-buildpacks#remove-classic-buildpacks

			Note: This error replaces the deprecation warning which was
			displayed in build logs starting 13th December 2024.
		EOF
		meta_set "failure_reason" "checks::duplicate-python-buildpack"
		exit 1
	fi
}

function checks::warn_if_existing_python_dir_present() {
	local build_dir="${1}"

	# We use `-e` here to catch the case where `python` is a file rather than a directory.
	if [[ -e "${build_dir}/.heroku/python" ]]; then
		output::error <<-EOF
			Error: Existing '.heroku/python/' directory found.

			Your app's source code contains an existing directory named
			'.heroku/python/', which is where the Python buildpack needs
			to install its files. This existing directory contains:

			$(find .heroku/python/ -maxdepth 2 || true)

			Writing to internal locations used by the Python buildpack
			isn't supported and can cause unexpected errors.

			If you have committed a '.heroku/python/' directory to your
			Git repo, you must delete it or use a different location.

			Otherwise, check that an earlier buildpack or 'bin/pre_compile'
			hook hasn't created this directory.

			Note: This error replaces the deprecation warning which was
			displayed in build logs starting 13th December 2024.
		EOF
		meta_set "failure_reason" "checks::existing-python-dir"
		exit 1
	fi
}
