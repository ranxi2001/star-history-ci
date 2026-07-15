#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bash -n \
  "$root/scripts/normalize-star-history.sh" \
  "$root/scripts/render-charts.sh" \
  "$root/scripts/publish-output.sh"

mkdir -p "$tmp/normalize"
printf 'new' > "$tmp/normalize/chart-light.svg"
printf 'old' > "$tmp/normalize/chart-light-20260101.svg"
OUTPUT_DIR="$tmp/normalize" \
FILE_PREFIX=chart \
THEMES=light \
GITHUB_OUTPUT="$tmp/normalize.out" \
bash "$root/scripts/normalize-star-history.sh" >/dev/null
test "$(cat "$tmp/normalize/chart-light.svg")" = new
test ! -e "$tmp/normalize/chart-light-20260101.svg"

if GITHUB_TOKEN=fake \
   REPOS=fixture/example \
   OUTPUT_DIR="$tmp/invalid" \
   FILE_PREFIX=../invalid \
   TYPE=Date \
   THEMES=light \
   WIDTH=480 \
   ACTION_PATH="$root" \
   GITHUB_OUTPUT="$tmp/invalid.out" \
   bash "$root/scripts/render-charts.sh" >/dev/null 2>&1; then
  echo "Invalid file prefix was accepted" >&2
  exit 1
fi

mkdir -p "$tmp/server/owner" "$tmp/source"
git init -q --bare "$tmp/server/owner/repo.git"
printf '<svg>one</svg>\n' > "$tmp/source/chart.svg"
printf 'state\n' > "$tmp/source/.state"

PUBLISH_TOKEN=fake \
PUBLISH_DIR="$tmp/source" \
PUBLISH_BRANCH=output \
FORCE_ORPHAN=true \
REPOSITORY=owner/repo \
SERVER_URL="file://$tmp/server" \
SOURCE_SHA=first \
bash "$root/scripts/publish-output.sh" >/dev/null

git clone -q --branch output "$tmp/server/owner/repo.git" "$tmp/check"
test "$(cat "$tmp/check/chart.svg")" = '<svg>one</svg>'
test -f "$tmp/check/.state"
test -f "$tmp/check/.nojekyll"

printf '<svg>two</svg>\n' > "$tmp/source/chart.svg"
PUBLISH_TOKEN=fake \
PUBLISH_DIR="$tmp/source" \
PUBLISH_BRANCH=output \
FORCE_ORPHAN=false \
REPOSITORY=owner/repo \
SERVER_URL="file://$tmp/server" \
SOURCE_SHA=second \
bash "$root/scripts/publish-output.sh" >/dev/null

rm -rf "$tmp/check"
git clone -q --branch output "$tmp/server/owner/repo.git" "$tmp/check"
test "$(cat "$tmp/check/chart.svg")" = '<svg>two</svg>'
test "$(git -C "$tmp/check" rev-list --count HEAD)" = 2

echo "local script tests passed"
