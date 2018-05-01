# Automatic configuration for Gunicorn's ForwardedAllowIPS setting.
export FORWARDED_ALLOW_IPS='*'

# Automatic configuration for Gunicorn's stdout access log setting.
export GUNICORN_CMD_ARGS=${GUNICORN_CMD_ARGS:-"--access-logfile -"}
