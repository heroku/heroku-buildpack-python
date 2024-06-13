#!/usr/bin/env bash

# Note: Since this is a .profile.d/ script it will be sourced, meaning that we cannot enable
# exit on error, have to use return not exit, and returning non-zero doesn't have an effect.

# Automatic configuration for Gunicorn's ForwardedAllowIPS setting.
export FORWARDED_ALLOW_IPS='*'

# Automatic configuration for Gunicorn's stdout access log setting.
export GUNICORN_CMD_ARGS=${GUNICORN_CMD_ARGS:-"--access-logfile -"}
