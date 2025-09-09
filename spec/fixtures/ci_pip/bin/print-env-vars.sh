#!/usr/bin/env bash

set -euo pipefail

printenv | sort | grep -vE '^(_|BUILDPACK_LOG_FILE|CI_NODE_.+|DYNO|HEROKU_TEST_RUN_.+|HOME|OLDPWD|PORT|PWD|SHLVL|STACK|TERM)='
