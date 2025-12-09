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
	elif [[ -f "${build_dir}/Pipfile" ]]; then
		output::error <<-'EOF'
			Error: No 'Pipfile.lock' found!

			A 'Pipfile' file was found, however, the associated 'Pipfile.lock'
			Pipenv lockfile wasn't. This means your app dependency versions
			aren't pinned, which means the package versions used on Heroku
			might not match those installed in other environments.

			Using Pipenv in this way is unsafe and no longer supported.

			Run 'pipenv lock' locally to generate the lockfile, and make sure
			that 'Pipfile.lock' isn't listed in '.gitignore' or '.slugignore'.

			Alternatively, if you wish to switch to another package manager,
			delete your 'Pipfile' and then add either a 'requirements.txt',
			'poetry.lock' or 'uv.lock' file.

			If you aren't sure which package manager to use, we recommend
			trying uv, since it supports lockfiles, is extremely fast, and
			is actively maintained by a full-time team:
			https://docs.astral.sh/uv/
		EOF
		build_data::set_string "failure_reason" "package-manager::pipenv-missing-lockfile"
		exit 1
	fi

	if [[ -f "${build_dir}/requirements.txt" ]]; then
		package_managers_found+=(pip)
		package_managers_found_display_text+=("requirements.txt (pip)")
	fi

	if [[ -f "${build_dir}/poetry.lock" ]]; then
		package_managers_found+=(poetry)
		package_managers_found_display_text+=("poetry.lock (Poetry)")
	fi

	if [[ -f "${build_dir}/uv.lock" ]]; then
		package_managers_found+=(uv)
		package_managers_found_display_text+=("uv.lock (uv)")
	fi

	local num_package_managers_found=${#package_managers_found[@]}

	case "${num_package_managers_found}" in
		1)
			echo "${package_managers_found[0]}"
			return 0
			;;
		0)
			if [[ -f "${build_dir}/setup.py" ]]; then
				output::error <<-EOF
					Error: Implicit setup.py file support has been sunset.

					Your app currently only has a setup.py file and no Python
					package manager files. This means that the buildpack can't
					tell which package manager you want to use, and whether to
					install your project in editable mode or not.

					Previously the buildpack guessed and used pip to install your
					dependencies in editable mode. However, this fallback was
					deprecated in September 2025 and has now been sunset.

					You must now add an explicit package manager file to your app,
					such as a requirements.txt, poetry.lock or uv.lock file.

					To continue using your setup.py file with pip in editable
					mode, create a new file in the root directory of your app
					named 'requirements.txt' containing the requirement
					'--editable .' (without quotes).

					Alternatively, if you wish to switch to another package
					manager, we recommend uv, since it supports lockfiles, is
					faster, and is actively maintained by a full-time team:
					https://docs.astral.sh/uv/
				EOF
				build_data::set_string "failure_reason" "package-manager::setup-py-only"
				exit 1
			fi

			output::error <<-EOF
				Error: Couldn't find any supported Python package manager files.

				A Python app on Heroku must have either a 'requirements.txt',
				'Pipfile.lock', 'poetry.lock' or 'uv.lock' package manager file
				in the root directory of its source code.

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
			build_data::set_string "failure_reason" "package-manager::none-found"
			exit 1
			;;
		*)
			output::error <<-EOF
				Error: Multiple Python package manager files were found.

				Exactly one package manager file should be present in your app's
				source code, however, several were found:

				$(printf -- "%s\n" "${package_managers_found_display_text[@]}")

				Previously, the buildpack guessed which package manager to use
				and installed your dependencies with the first package manager
				listed above. However, this implicit behaviour was deprecated
				in November 2024 and is now no longer supported.

				You must decide which package manager you want to use with your
				app, and then delete the file(s) and any config from the others.

				If you aren't sure which package manager to use, we recommend
				trying uv, since it supports lockfiles, is extremely fast, and
				is actively maintained by a full-time team:
				https://docs.astral.sh/uv/

				Note: If you use a third-party uv or Poetry buildpack, you must
				remove it from your app, since it's no longer required and the
				requirements.txt file it generates will trigger this error. See:
				https://devcenter.heroku.com/articles/managing-buildpacks#remove-classic-buildpacks
			EOF
			build_data::set_string "failure_reason" "package-manager::multiple-found"
			build_data::set_string "failure_detail" "$(
				IFS=,
				echo "${package_managers_found[*]}"
			)"
			exit 1
			;;
	esac
}
