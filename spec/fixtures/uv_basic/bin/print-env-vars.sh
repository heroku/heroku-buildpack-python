#!/usr/bin/env bash

set -euo pipefail

printenv | sort | grep -vE '^(_|BUILDPACK_LOG_FILE|DYNO|HOME|OLDPWD|PORT|PS1|PWD|REQUEST_ID|SHLVL|SOURCE_VERSION|STACK|TERM)='
