from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

INSTALLED_APPS = [
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    # The staticfiles app (which is what provides the collectstatic command) is not enabled.
    # "django.contrib.staticfiles",
]

STATIC_ROOT = BASE_DIR / "staticfiles"
STATIC_URL = "static/"
