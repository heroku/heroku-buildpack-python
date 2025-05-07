#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

function package_manager::determine_package_manager() {
	local build_dir="${1}"
	local package_managers_found=()
	local package_managers_found_display_text=()

	if [[ -f "${build_dir}/Pipfile.lock" ]]; then
		package_managers_found+=(pipenv)
		package_managers_found_display_text+=("Pipfile.lock (Pipenv)")
		meta_set "pipenv_has_lockfile" "true"
	elif [[ -f "${build_dir}/Pipfile" ]]; then
		# TODO: Start requiring a Pipfile.lock and make this branch a "missing lockfile" error instead.
		output::warning <<-'EOF'
			Warning: No 'Pipfile.lock' found!

			A 'Pipfile' file was found, however, the associated 'Pipfile.lock'
			Pipenv lockfile was not. This means your app dependency versions
			aren't pinned, which means the package versions used on Heroku
			might not match those installed in other environments.

			For now, we will install your dependencies without a lockfile,
			however, in the future this warning will become an error.

			Run 'pipenv lock' locally to generate the lockfile, and make sure
			that 'Pipfile.lock' isn't listed in '.gitignore' or '.slugignore'.
		EOF
		package_managers_found+=(pipenv)
		package_managers_found_display_text+=("Pipfile (Pipenv)")
		meta_set "pipenv_has_lockfile" "false"
	fi

	if [[ -f "${build_dir}/requirements.txt" ]]; then
		package_managers_found+=(pip)
		package_managers_found_display_text+=("requirements.txt (pip)")
	fi

	# This must be after the requirements.txt check, so that the requirements.txt exported by
	# `python-poetry-buildpack` takes precedence over poetry.lock, for consistency with the
	# behaviour prior to this buildpack supporting Poetry natively. In the future the presence
	# of multiple package manager files will be turned into an error, at which point the
	# ordering here won't matter.
	if [[ -f "${build_dir}/poetry.lock" ]]; then
		package_managers_found+=(poetry)
		package_managers_found_display_text+=("poetry.lock (Poetry)")
	fi

	if [[ -f "${build_dir}/uv.lock" ]]; then
		package_managers_found+=(uv)
		package_managers_found_display_text+=("uv.lock (uv)")
	fi

	# TODO: Deprecate/sunset this fallback, since using setup.py declared dependencies is
	# not a best practice, and we can only guess as to which package manager to use.
	if ((${#package_managers_found[@]} == 0)) && [[ -f "${build_dir}/setup.py" ]]; then
		package_managers_found+=(pip)
		package_managers_found_display_text+=("setup.py (pip)")
		meta_set "setup_py_only" "true"
	else
		meta_set "setup_py_only" "false"
	fi

	local num_package_managers_found=${#package_managers_found[@]}

	case "${num_package_managers_found}" in
		1)
			echo "${package_managers_found[0]}"
			return 0
			;;
		0)
			output::error <<-EOF
				Error: Couldn't find any supported Python package manager files.

				A Python app on Heroku must have either a 'requirements.txt',
				'Pipfile', 'poetry.lock' or 'uv.lock' package manager file in
				the root directory of its source code.

				Currently the root directory of your app contains:

				$(ls -1A --indicator-style=slash "${build_dir}" || true)

				If your app already has a package manager file, check that it:

				1. Is in the top level directory (not a subdirectory).
				2. Has the correct spelling (the filenames are case-sensitive).
				3. Isn't listed in '.gitignore' or '.slugignore'.
				4. Has been added to the Git repository using 'git add --all'
				   and then committed using 'git commit'.

				Otherwise, add a package manager file to your app. If your app has
				no dependencies, then create an empty 'requirements.txt' file.

				If you aren't sure which package manager to use, we recommend
				trying uv, since it supports lockfiles, is extremely fast, and
				is actively maintained by a full-time team:
				https://docs.astral.sh/uv/

				For help with using Python on Heroku, see:
				https://devcenter.heroku.com/articles/getting-started-with-python
				https://devcenter.heroku.com/articles/python-support
			EOF
			meta_set "failure_reason" "package-manager::none-found"
			exit 1
			;;
		*)
			# If multiple package managers are found, use the first found above.
			# TODO: Turn this case into an error since it results in support tickets from users
			# who don't realise they have multiple package manager files and think their changes
			# aren't taking effect. (We'll need to wait until after Poetry support has landed,
			# and people have had a chance to migrate from the Poetry buildpack mentioned above.)
			echo "${package_managers_found[0]}"

			output::warning <<-EOF
				Warning: Multiple Python package manager files were found.

				Exactly one package manager file should be present in your app's
				source code, however, several were found:

				$(printf -- "%s\n" "${package_managers_found_display_text[@]}")

				For now, we will build your app using the first package manager
				listed above, however, in the future this warning will become
				an error.

				Decide which package manager you want to use with your app, and
				then delete the file(s) and any config from the others.

				If you aren't sure which package manager to use, we recommend
				trying uv, since it supports lockfiles, is extremely fast, and
				is actively maintained by a full-time team:
				https://docs.astral.sh/uv/
			EOF

			if [[ "${package_managers_found[*]}" == *"poetry"* ]]; then
				output::notice <<-EOF
					Note: We recently added support for the package manager Poetry.
					If you are using a third-party Poetry buildpack you must remove
					it, otherwise the requirements.txt file it generates will cause
					the warning above.
				EOF
			fi

			if [[ "${package_managers_found[*]}" == *"uv"* ]]; then
				output::notice <<-EOF
					Note: We recently added support for the package manager uv.
					If you are using a third-party uv buildpack you must remove
					it, otherwise the requirements.txt file it generates will cause
					the warning above.
				EOF
			fi

			meta_set "package_manager_multiple_found" "$(
				IFS=,
				echo "${package_managers_found[*]}"
			)"
			return 0
			;;
	esac
}
