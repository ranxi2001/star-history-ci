#!/usr/bin/env bash
set -euo pipefail

publish_dir="${PUBLISH_DIR:-}"
publish_branch="${PUBLISH_BRANCH:-output}"
publish_token="${PUBLISH_TOKEN:-}"
force_orphan="${FORCE_ORPHAN:-true}"
repository="${REPOSITORY:-${GITHUB_REPOSITORY:-}}"
server_url="${SERVER_URL:-${GITHUB_SERVER_URL:-https://github.com}}"
source_sha="${SOURCE_SHA:-${GITHUB_SHA:-unknown}}"

if [ -z "$publish_token" ]; then
  echo "::error::github-token input is empty."
  exit 1
fi
if [ -z "$repository" ]; then
  echo "::error::Repository is not available from the GitHub Actions context."
  exit 1
fi
if [ ! -d "$publish_dir" ]; then
  echo "::error::Publish directory '$publish_dir' does not exist."
  exit 1
fi
if [ -e "$publish_dir/.git" ] || [ -L "$publish_dir/.git" ]; then
  echo "::error::Publish directory must not be a Git working tree. Use a dedicated output directory."
  exit 1
fi
if ! git check-ref-format --branch "$publish_branch" >/dev/null 2>&1; then
  echo "::error::Invalid publish branch '$publish_branch'."
  exit 1
fi
if [ "$force_orphan" != "true" ] && [ "$force_orphan" != "false" ]; then
  echo "::error::force-orphan must be true or false."
  exit 1
fi

publish_dir="$(cd "$publish_dir" && pwd -P)"
server_url="${server_url%/}"
remote_url="$server_url/$repository.git"
tmp="$(mktemp -d)"

cleanup() {
  unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
  unset publish_token auth_header
  rm -rf "$tmp"
}
trap cleanup EXIT

auth_header="$(printf 'x-access-token:%s' "$publish_token" | base64 | tr -d '\r\n')"
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="http.${server_url}/.extraheader"
export GIT_CONFIG_VALUE_0="AUTHORIZATION: basic $auth_header"

repo_dir="$tmp/repository"
git init -q "$repo_dir"
cd "$repo_dir"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add origin "$remote_url"

if [ "$force_orphan" = "false" ] && \
   git fetch -q --depth=1 origin "refs/heads/$publish_branch:refs/remotes/origin/$publish_branch"; then
  git checkout -q -B "$publish_branch" "refs/remotes/origin/$publish_branch"
  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
else
  git checkout -q --orphan "$publish_branch"
fi

cp -R "$publish_dir"/. .
touch .nojekyll
git add -A

if git diff --cached --quiet; then
  echo "Published files are unchanged; nothing to push."
  exit 0
fi

git commit -q -m "deploy: $source_sha"
if [ "$force_orphan" = "true" ]; then
  git push -q --force origin "HEAD:refs/heads/$publish_branch"
else
  git push -q origin "HEAD:refs/heads/$publish_branch"
fi
echo "Published '$publish_dir' to '$publish_branch'."
