import os
import re
import unittest

DATABASES = {}
ROOTDIR = os.path.dirname(__file__)

class TestInjectDBs(unittest.TestCase):
    def setUp(self):
        DATABASES = {}
        os.environ.update({
            "DATABASE_URL":                 "postgres://victor:xray@localhost:5432/alfa",
            "HEROKU_POSTGRESQL_ONYX_URL":   "postgres://victor:xray@localhost:5432/alfa",
            "HEROKU_POSTGRESQL_RED_URL":    "postgres://juliet:zulu@localhost:5432/beta",
            "SHARED_DATABASE_URL":          "postgres://quebec:kilo@localhost:5432/echo",
            "THUNK":                        "postgres://localhost/db",
            "FOO":                          "bar",
        })

    def testCode(self):
        """
        Test the code injected into settings.py to map ENV to settings.DATABASES hash
        """
        # read and exec code in this context
        with open(os.path.join(ROOTDIR, "..", "opt/dbs.py")) as _src:
            exec compile(_src.read(), "dbs.py", "exec")

        self.assertEqual(5, len(DATABASES)) # default, DATABASE, ONYX, RED, SHARED_DATABASE

        self.assertDictEqual({
            "ENGINE":   "django.db.backends.postgresql_psycopg2",
            "NAME":     "alfa",
            "USER":     "victor",
            "PASSWORD": "xray",
            "HOST":     "localhost",
            "PORT":     5432
        }, DATABASES["HEROKU_POSTGRESQL_ONYX"])

        self.assertDictEqual({
            "ENGINE":   "django.db.backends.postgresql_psycopg2",
            "NAME":     "beta",
            "USER":     "juliet",
            "PASSWORD": "zulu",
            "HOST":     "localhost",
            "PORT":     5432
        }, DATABASES["HEROKU_POSTGRESQL_RED"])

        self.assertDictEqual({
            "ENGINE":   "django.db.backends.postgresql_psycopg2",
            "NAME":     "echo",
            "USER":     "quebec",
            "PASSWORD": "kilo",
            "HOST":     "localhost",
            "PORT":     5432
        }, DATABASES["SHARED_DATABASE"])

        # aliases
        self.assertDictEqual(DATABASES["HEROKU_POSTGRESQL_ONYX"], DATABASES["DATABASE"])
        self.assertDictEqual(DATABASES["HEROKU_POSTGRESQL_ONYX"], DATABASES["default"])

if __name__ == "__main__":
    unittest.main()