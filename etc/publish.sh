#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit

buildpack_registry_name="heroku/python"

function abort() {
	echo
	echo "Error: ${1}" >&2
	exit 1
}

echo "Checking environment..."

if ! command -v gh >/dev/null; then
	abort "Install the GitHub CLI first: https://cli.github.com"
fi

if ! heroku buildpacks:publish --help >/dev/null; then
	abort "Install the Buildpack Registry plugin first: https://github.com/heroku/plugin-buildpack-registry"
fi

# Explicitly check the CLI is logged in, since the Buildpack Registry plugin doesn't handle re-authing
# expired logins properly, which can otherwise lead to the release aborting partway through.
if ! heroku whoami >/dev/null; then
	abort "Log into the Heroku CLI first: heroku login"
fi

echo "Checking buildpack versions in sync..."
current_github_release_version=$(gh release view --json tagName --jq '.tagName' | tr --delete 'v')
current_registry_version="$(heroku buildpacks:versions "${buildpack_registry_name}" | awk 'FNR == 3 { print $1 }')"

if [[ "${current_github_release_version}" != "${current_registry_version}" ]]; then
	abort "The current GitHub release version (v${current_github_release_version}) does not match the registry version (v${current_registry_version}), likely due to a registry rollback. Fix this first!"
fi

new_version="$((current_github_release_version + 1))"
new_git_tag="v${new_version}"

echo "Extracting changelog entry for this release..."
git fetch origin
# Using `git show` to avoid having to disrupt the current branch/working directory.
changelog_entry="$(git show origin/main:CHANGELOG.md | awk "/^## \[v${new_version}\]/{flag=1; next} /^## /{flag=0} flag")"

if [[ -n "${changelog_entry}" ]]; then
	echo -e "${changelog_entry}\n"
else
	abort "Unable to find changelog entry for v${new_version}. Has the prepare release PR been triggered/merged?"
fi

read -r -p "Deploy as ${new_git_tag} [y/n]? " choice
case "${choice}" in
	y | Y) ;;
	n | N) exit 0 ;;
	*) exit 1 ;;
esac

echo -e "\nCreating GitHub release..."
gh release create "${new_git_tag}" --title "${new_git_tag}" --notes "${changelog_entry}"

echo -e "\nPublishing to the Heroku Buildpack Registry..."
heroku buildpacks:publish "${buildpack_registry_name}" "${new_git_tag}"
echo
heroku buildpacks:versions "${buildpack_registry_name}" | head -n 3
