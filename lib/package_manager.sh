#!/usr/bin/env bash

function package_manager::determine_package_manager() {
	local build_dir="${1}"
	local package_managers_found=()

	if [[ -f "${build_dir}/Pipfile.lock" ]]; then
		package_managers_found+=(pipenv)
		meta_set "pipenv_has_lockfile" "true"
	elif [[ -f "${build_dir}/Pipfile" ]]; then
		# TODO: Start requiring a Pipfile.lock and make this branch a "missing lockfile" error instead.
		package_managers_found+=(pipenv)
		meta_set "pipenv_has_lockfile" "false"
	fi

	if [[ -f "${build_dir}/requirements.txt" ]]; then
		package_managers_found+=(pip)
	fi

	# TODO: Deprecate/sunset this fallback, since using setup.py declared dependencies is
	# not a best practice, and we can only guess as to which package manager to use.
	if ((${#package_managers_found[@]} == 0)) && [[ -f "${build_dir}/setup.py" ]]; then
		package_managers_found+=(pip)
		meta_set "setup_py_only" "true"
	else
		meta_set "setup_py_only" "false"
	fi

	case "${#package_managers_found[@]}" in
		1)
			echo "${package_managers_found[0]}"
			return 0
			;;
		0)
			display_error <<-EOF
				Error: Couldn't find any supported Python package manager files.

				A Python app on Heroku must have either a 'requirements.txt' or
				'Pipfile' package manager file in the root directory of its
				source code.

				Currently the root directory of your app contains:

				$(ls -1 --indicator-style=slash "${build_dir}" || true)

				If your app already has a package manager file, check that it:

				1. Is in the top level directory (not a subdirectory).
				2. Has the correct spelling (the filenames are case-sensitive).
				3. Isn't listed in '.gitignore' or '.slugignore'.

				Otherwise, add a package manager file to your app. If your app has
				no dependencies, then create an empty 'requirements.txt' file.

				For help with using Python on Heroku, see:
				https://devcenter.heroku.com/articles/getting-started-with-python
				https://devcenter.heroku.com/articles/python-support
			EOF
			meta_set "failure_reason" "package-manager-not-found"
			return 1
			;;
		*)
			# If multiple package managers are found, use the first found above.
			# TODO: Turn this case into an error since it results in support tickets from users
			# who don't realise they have multiple package manager files and think their changes
			# aren't taking effect. (We'll need to wait until after Poetry support has landed,
			# and people have had a chance to migrate from the third-party Poetry buildpack,
			# since using it results in both a requirements.txt and a poetry.lock.)
			echo "${package_managers_found[0]}"
			meta_set "package_manager_multiple_found" "$(
				IFS=,
				echo "${package_managers_found[*]}"
			)"
			return 0
			;;
	esac
}
