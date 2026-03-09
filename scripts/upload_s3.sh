#!/usr/bin/env bash
set -euo pipefail

if [ -z "${INPUT_S3_BUCKET}" ]; then
  echo "s3-bucket is required when upload-target is s3 or both"
  exit 1
fi

case "${INPUT_APPEND_RESOLVED_NAME_TO_S3_PREFIX}" in
  true|false) ;;
  *)
    echo "Invalid append-resolved-name-to-s3-prefix value: ${INPUT_APPEND_RESOLVED_NAME_TO_S3_PREFIX} (expected true|false)"
    exit 1
    ;;
esac

if [ "${INPUT_S3_FORCE_PATH_STYLE}" = "true" ]; then
  aws configure set default.s3.addressing_style path
elif [ "${INPUT_S3_FORCE_PATH_STYLE}" != "false" ]; then
  echo "Invalid s3-force-path-style value: ${INPUT_S3_FORCE_PATH_STYLE} (expected true|false)"
  exit 1
fi

endpoint_args=()
if [ -n "${INPUT_S3_ENDPOINT_URL}" ]; then
  endpoint_args+=(--endpoint-url "${INPUT_S3_ENDPOINT_URL}")
fi

prefix="${INPUT_S3_PREFIX}"
if [ "${INPUT_APPEND_RESOLVED_NAME_TO_S3_PREFIX}" = "true" ]; then
  if [ -n "$prefix" ]; then
    prefix="${prefix%/}/${RESOLVED_NAME}"
  else
    prefix="${RESOLVED_NAME}"
  fi
fi
prefix="${prefix#/}"
if [ -n "$prefix" ] && [ "${prefix: -1}" != "/" ]; then
  prefix="$prefix/"
fi
dest="s3://${INPUT_S3_BUCKET}/${prefix}"

shopt -s globstar nullglob

include_args=(--exclude "*")
found=0
while IFS= read -r raw; do
  p="$(echo "$raw" | xargs)"
  [ -z "$p" ] && continue

  if [ -d "$p" ]; then
    include_args+=(--include "$p/**")
  else
    include_args+=(--include "$p")
  fi

  matches=( $p )
  if [ ${#matches[@]} -gt 0 ]; then
    found=1
  fi
done <<< "${INPUT_PATH}"

if [ "$found" -eq 0 ]; then
  case "${INPUT_IF_NO_FILES_FOUND}" in
    error)
      echo "No files found for path patterns."
      exit 1
      ;;
    warn)
      echo "Warning: no files found for path patterns."
      exit 0
      ;;
    ignore)
      exit 0
      ;;
    *)
      echo "Invalid if-no-files-found value: ${INPUT_IF_NO_FILES_FOUND}"
      exit 1
      ;;
  esac
fi

aws s3 sync . "$dest" "${endpoint_args[@]}" "${include_args[@]}"
echo "Uploaded matching files to $dest"
