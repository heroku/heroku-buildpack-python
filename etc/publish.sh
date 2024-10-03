#!/usr/bin/env bash
# shellcheck disable=SC2250 # TODO: Use braces around variable references even when not strictly required.

set -euo pipefail
shopt -s inherit_errexit

BP_NAME=${1:-"heroku/python"}

curVersion=$(heroku buildpacks:versions "$BP_NAME" | awk 'FNR == 3 { print $1 }')
newVersion="v$((curVersion + 1))"

read -r -p "Deploy as version: $newVersion [y/n]? " choice
case "$choice" in
	y | Y) echo "" ;;
	n | N) exit 0 ;;
	*) exit 1 ;;
esac

git fetch origin
originMain=$(git rev-parse origin/main)
echo "Tagging commit $originMain with $newVersion... "
git tag "$newVersion" "${originMain:?}"
git push origin "refs/tags/${newVersion}"

echo -e "\nPublishing to the buildpack registry..."
heroku buildpacks:publish "$BP_NAME" "$newVersion"
echo
heroku buildpacks:versions "${BP_NAME}" | head -n 3
