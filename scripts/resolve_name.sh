#!/usr/bin/env bash
set -euo pipefail

base_name="${INPUT_NAME}"
template="${INPUT_NAME_TEMPLATE}"
version_input="${INPUT_VERSION}"
version_source="${INPUT_VERSION_SOURCE}"
build_type="${INPUT_BUILD_TYPE}"
obfuscated="${INPUT_OBFUSCATED}"
sanitize="${INPUT_SANITIZE_NAME}"
append_max_detail_suffix="${INPUT_APPEND_MAX_DETAIL_SUFFIX}"

case "$version_source" in
  none|git-tag|git-describe) ;;
  *)
    echo "Invalid version-source: $version_source (expected none|git-tag|git-describe)"
    exit 1
    ;;
esac

case "$build_type" in
  ""|debug|release) ;;
  *)
    echo "Invalid build-type: $build_type (expected debug|release)"
    exit 1
    ;;
esac

case "$obfuscated" in
  true|false) ;;
  *)
    echo "Invalid obfuscated: $obfuscated (expected true|false)"
    exit 1
    ;;
esac

case "$sanitize" in
  true|false) ;;
  *)
    echo "Invalid sanitize-name: $sanitize (expected true|false)"
    exit 1
    ;;
esac

case "$append_max_detail_suffix" in
  true|false) ;;
  *)
    echo "Invalid append-max-detail-suffix: $append_max_detail_suffix (expected true|false)"
    exit 1
    ;;
esac

resolved_version="$version_input"
if [ -z "$resolved_version" ]; then
  case "$version_source" in
    none)
      resolved_version=""
      ;;
    git-tag)
      resolved_version="$(git describe --tags --exact-match 2>/dev/null || true)"
      ;;
    git-describe)
      resolved_version="$(git describe --tags --always --dirty 2>/dev/null || true)"
      ;;
  esac
fi

sha="$(git rev-parse --short HEAD 2>/dev/null || true)"
if [ -z "$sha" ] && [ -n "${GITHUB_SHA:-}" ]; then
  sha="${GITHUB_SHA:0:7}"
fi

obf_suffix=""
if [ "$obfuscated" = "true" ]; then
  obf_suffix="-obf"
fi

run_number="${GITHUB_RUN_NUMBER:-}"
resolved_name="$template"
resolved_name="${resolved_name//\{name\}/$base_name}"
resolved_name="${resolved_name//\{version\}/$resolved_version}"
resolved_name="${resolved_name//\{build_type\}/$build_type}"
resolved_name="${resolved_name//\{obfuscated\}/$obfuscated}"
resolved_name="${resolved_name//\{obf_suffix\}/$obf_suffix}"
resolved_name="${resolved_name//\{sha\}/$sha}"
resolved_name="${resolved_name//\{run_number\}/$run_number}"

if [ "$append_max_detail_suffix" = "true" ]; then
  detail_parts=()
  if [ -n "$resolved_version" ]; then
    detail_parts+=("$resolved_version")
  fi
  if [ -n "$build_type" ]; then
    detail_parts+=("$build_type")
  fi
  if [ "$obfuscated" = "true" ]; then
    detail_parts+=("obf")
  #else
    #detail_parts+=("plain")
  fi
  # if [ -n "$sha" ]; then
  #   detail_parts+=("$sha")
  # fi

  # if [ -n "$run_number" ]; then
  #   detail_parts+=("run$run_number")
  # fi

  if [ ${#detail_parts[@]} -gt 0 ]; then
    detail_suffix="$(IFS=-; echo "${detail_parts[*]}")"
    resolved_name="${resolved_name}-${detail_suffix}"
  fi
fi

if [ "$sanitize" = "true" ]; then
  resolved_name="$(printf '%s' "$resolved_name" | tr '[:space:]' '-' | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
fi
if [ -z "$resolved_name" ]; then
  resolved_name="$base_name"
fi

echo "resolved-name=$resolved_name" >> "$GITHUB_OUTPUT"
echo "resolved-version=$resolved_version" >> "$GITHUB_OUTPUT"
