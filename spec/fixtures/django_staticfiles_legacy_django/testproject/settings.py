import os
import sys
from pathlib import Path
from pprint import pprint

BASE_DIR = Path(__file__).resolve().parent.parent

INSTALLED_APPS = [
    "django.contrib.staticfiles",
    "testapp",
]

STATIC_ROOT = BASE_DIR / "staticfiles"
STATIC_URL = "static/"

# Older versions of Django require that `SECRET_KEY` is set when running collectstatic.
SECRET_KEY = "example"

ENV_VARS_TO_OMIT = {
    "_",
    "BUILDPACK_LOG_FILE",
    "DYNO",
    "HOME",
    "OLDPWD",
    "REQUEST_ID",
    "SHLVL",
    "SOURCE_VERSION",
    "STACK",
}
pprint({k: v for k, v in os.environ.items() if k not in ENV_VARS_TO_OMIT})
print()
pprint(sys.path)

# Tests that app env vars are passed to the 'manage.py' script invocations.
assert "EXPECTED_ENV_VAR" in os.environ
