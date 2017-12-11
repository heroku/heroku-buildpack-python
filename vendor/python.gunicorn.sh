# Automatic configuration for Gunicorn's ForwardedAllowIPS setting.
export FORWARDED_ALLOW_IPS='*'
export GUNICORN_CMD_ARGS="--access-logfile -"
