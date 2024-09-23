#!/usr/bin/env bash

set -euo pipefail

printenv | sort \
  | grep -vE '^(_|BUILDPACK_LOG_FILE|DYNO|OLDPWD|REQUEST_ID|SHLVL)=' \
  | sed --regexp-extended \
      --expression 's#(=/tmp/build_)[^:/]+#\1<hash>#' \
      --expression 's#^(ENV_DIR=/tmp/).*#\1...#' \
      --expression 's#^(SOURCE_VERSION=).*#\1...#'
