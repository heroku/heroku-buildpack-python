#!/usr/bin/env bash

# Based on:
# https://raw.githubusercontent.com/heroku/buildpack-stdlib/v8/stdlib.sh

# Standard Output
# ---------------

# Buildpack Steps.
puts_step() {
  if [[ "$*" == "-" ]]; then
    read -r output
  else
    output=$*
  fi
  echo -e "\\e[1m\\e[36m=== $output\\e[0m"
  unset output
}

# Buildpack Error.
puts_error() {
  if [[ "$*" == "-" ]]; then
    read -r output
  else
    output=$*
  fi
  echo -e "\\e[1m\\e[31m=!= $output\\e[0m"
}

# Buildpack Warning.
puts_warn() {
  if [[ "$*" == "-" ]]; then
    read -r output
  else
    output=$*
  fi
  echo -e "\\e[1m\\e[33m=!= $output\\e[0m"
}

# Is verbose set?
is_verbose() {
  if [[ -n $BUILDPACK_VERBOSE ]]; then
    return 0
  else
    return 1
  fi
}

# Buildpack Verbose.
puts_verbose() {
  if is_verbose; then
    if [[ "$*" == "-" ]]; then
      read -r output
    else
      output=$*
    fi
    echo "$output"
    unset output
  fi
}

# Buildpack Utilities
# -------------------

# Usage: $ set-env key value
# NOTICE: Expects PROFILE_PATH & EXPORT_PATH to be set!
set_env() {
  # TODO: automatically create profile path directory if it doesn't exist.
  echo "export $1=$2" >> "$PROFILE_PATH"
  echo "export $1=$2" >> "$EXPORT_PATH"
}

# Usage: $ set-default-env key value
# NOTICE: Expects PROFILE_PATH & EXPORT_PATH to be set!
set_default_env() {
  echo "export $1=\${$1:-$2}" >> "$PROFILE_PATH"
  echo "export $1=\${$1:-$2}" >> "$EXPORT_PATH"
}

# Usage: $ un-set-env key
# NOTICE: Expects PROFILE_PATH to be set!
un_set_env() {
  echo "unset $1" >> "$PROFILE_PATH"
}

# Usage: $ _env-blacklist pattern
# Outputs a regex of default blacklist env vars.
_env_blacklist() {
  local regex=${1:-''}
  if [[ -n "$regex" ]]; then
    regex="|$regex"
  fi
  echo "^(PATH|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|LD_LIBRARY_PATH|PYTHONHOME$regex)$"
}

# Usage: $ export-env ENV_DIR WHITELIST BLACKLIST
# Exports the environment variables defined in the given directory.
export_env() {
  local env_dir=${1:-$ENV_DIR}
  local whitelist=${2:-''}
  local blacklist
  blacklist="$(_env_blacklist "$3")"
  if [[ -d "$env_dir" ]]; then
    # Environment variable names won't contain characters affected by:
    # shellcheck disable=SC2045
    for e in $(ls "$env_dir"); do
      echo "$e" | grep -E "$whitelist" | grep -qvE "$blacklist" &&
      export "$e=$(cat "$env_dir/$e")"
      :
    done
  fi
}

# Usage: $ sub-env command
# Runs a subshell of specified command with user-provided config.
# NOTICE: Expects ENV_DIR to be set. WHITELIST & BLACKLIST are optional.
# Examples:
#    WHITELIST=${2:-''}
#    BLACKLIST=${3:-'^(GIT_DIR|PYTHONHOME|LD_LIBRARY_PATH|LIBRARY_PATH|PATH)$'}
sub_env() {
  (
    # TODO: Fix https://github.com/heroku/buildpack-stdlib/issues/37
    # shellcheck disable=SC2153
    export_env "$ENV_DIR" "$WHITELIST" "$BLACKLIST"

    "$@"
  )
}

# Returns the current time, in milliseconds.
nowms() {
  date +%s%3N
}
