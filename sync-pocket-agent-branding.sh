#!/usr/bin/env bash
# Copy canonical Pocket Agent logo into each pocket-agent* git repo (.github/).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/pocket-agent/.github/pocket-agent-image.png"
if [[ ! -f "$SRC" ]]; then
  SRC="${ROOT}/pocket-agent-image.png"
fi
if [[ ! -f "$SRC" ]]; then
  echo "Missing source image: pocket-agent/.github/pocket-agent-image.png or workspace pocket-agent-image.png"
  exit 1
fi

repos=(
  pocket-agent
  pocket-agent-web-app
  pocket-agent-api-app
  pocket-agent-cli
  pocket-agent-desktop-app
  pocket-agent-wizard
  pocket-agent-sdk
  pocket-agent-landing-page
  pocket-agent-installer
)

for name in "${repos[@]}"; do
  dir="${ROOT}/${name}/.github"
  mkdir -p "$dir"
  dest="${dir}/pocket-agent-image.png"
  if [[ "$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")" != "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")" ]]; then
    cp "$SRC" "$dest"
  fi
  if [[ "$(cd "$(dirname "$dest")" && pwd)/$(basename "$dest")" != "$(cd "$(dirname "$dir")" && pwd)/screenshot.png" ]]; then
    cp "$dest" "${dir}/screenshot.png"
  fi
  echo "→ ${name}/.github/pocket-agent-image.png"
done

echo "Done."
