# Tests that manage.py alone doesn't trigger Django collectstatic.
raise RuntimeError("This is not a Django app, so manage.py should not be run!")
