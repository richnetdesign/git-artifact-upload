#!/usr/bin/env bash
set -euo pipefail

if command -v aws >/dev/null 2>&1; then
  aws --version
  exit 0
fi

python3 -m pip install --user awscli
echo "$HOME/.local/bin" >> "$GITHUB_PATH"
"$HOME/.local/bin/aws" --version
