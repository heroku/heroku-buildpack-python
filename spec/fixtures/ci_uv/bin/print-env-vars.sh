#!/usr/bin/env bash

set -euo pipefail

printenv | sort | grep -vE '^(_|BUILDPACK_LOG_FILE|BUILD_DIR|CACHE_DIR|CI_NODE_.+|DYNO|ENV_DIR|HEROKU_TEST_RUN_.+|HOME|OLDPWD|PORT|PWD|SHLVL|STACK|TERM)='
