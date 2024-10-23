#!/usr/bin/env bash

# This is technically redundant, since all consumers of this lib will have enabled these,
# however, it helps Shellcheck realise the options under which these functions will run.
set -euo pipefail

# Used to run the `bin/pre_compile` and `bin/post_compile`s scripts if found in the app source,
# allowing for build customisation.
function hooks::run_hook() {
	local hook_name="${1}"
	local script_path="bin/${hook_name}"

	if [[ -f "${script_path}" ]]; then
		local hook_start_time
		hook_start_time=$(nowms)
		output::step "Running ${script_path} hook"
		meta_set "${hook_name}_hook" "true"
		chmod +x "${script_path}"

		# shellcheck disable=SC2310 # This function is invoked in an 'if' condition so set -e will be disabled.
		if ! sub_env "${script_path}" |& output::indent; then
			output::error <<-EOF
				Error: Failed to run the ${script_path} script.

				We found a '${script_path}' script in your app source, so ran
				it to allow for customisation of the build process.

				However, this script exited with a non-zero exit status.

				Fix any errors output by your script above, or remove/rename
				the script to prevent it from being run during the build.
			EOF
			meta_set "failure_reason" "hooks::${hook_name}"
			exit 1
		fi

		meta_time "${hook_name}_hook_duration" "${hook_start_time}"
	else
		meta_set "${hook_name}_hook" "false"
	fi
}
