#!/usr/bin/env bash
set -euo pipefail

output_dir="${OUTPUT_DIR:-star-history}"
prefix="${FILE_PREFIX:-star-history}"
themes_input="${THEMES:-light,dark}"
repository="${REPOSITORY:-${GITHUB_REPOSITORY:-}}"
publish_branch="${PUBLISH_BRANCH:-output}"

if [ ! -d "$output_dir" ]; then
  echo "::error::Output directory '$output_dir' does not exist."
  exit 1
fi

if ! [[ "$prefix" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "::error::Invalid file prefix '$prefix'. Use only letters, numbers, dot, underscore, and dash."
  exit 1
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

themes=()
IFS=',' read -ra raw_themes <<< "$themes_input"
for raw_theme in "${raw_themes[@]}"; do
  theme="$(trim "$raw_theme")"
  [ -z "$theme" ] && continue
  if ! [[ "$theme" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "::error::Invalid theme '$theme'. Use only letters, numbers, underscore, and dash."
    exit 1
  fi
  themes+=("$theme")
done

if [ "${#themes[@]}" -eq 0 ]; then
  echo "::error::No themes found in '$themes_input'."
  exit 1
fi

shopt -s nullglob

stable_files=()
light_path=""
dark_path=""

for theme in "${themes[@]}"; do
  stable="$output_dir/$prefix-$theme.svg"
  candidates=("$output_dir/$prefix-$theme-"*.svg)

  if [ "${#candidates[@]}" -gt 0 ]; then
    latest="$(printf '%s\n' "${candidates[@]}" | sort | tail -n 1)"
    mv -f "$latest" "$stable"
    rm -f "$output_dir/$prefix-$theme-"*.svg
  elif [ ! -f "$stable" ]; then
    echo "::warning::No generated SVG found for theme '$theme'."
    continue
  fi

  stable_files+=("$stable")
  [ "$theme" = "light" ] && light_path="$stable"
  [ "$theme" = "dark" ] && dark_path="$stable"
done

if [ "${#stable_files[@]}" -eq 0 ]; then
  echo "::error::No stable SVG files were produced in '$output_dir'."
  exit 1
fi

[ -z "$light_path" ] && light_path="${stable_files[0]}"

raw_base=""
if [ -n "$repository" ]; then
  raw_base="https://raw.githubusercontent.com/$repository/$publish_branch"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "light=$light_path"
    echo "dark=$dark_path"
    if [ -n "$raw_base" ]; then
      echo "light_url=$raw_base/$(basename "$light_path")"
      [ -n "$dark_path" ] && echo "dark_url=$raw_base/$(basename "$dark_path")"
    else
      echo "light_url="
      echo "dark_url="
    fi
    echo "files<<STAR_HISTORY_FILES"
    printf '%s\n' "${stable_files[@]}"
    echo "STAR_HISTORY_FILES"
  } >> "$GITHUB_OUTPUT"
fi

printf 'Stable star-history files:\n'
printf '  %s\n' "${stable_files[@]}"
