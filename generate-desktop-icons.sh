#!/usr/bin/env bash
# Generate Tauri icons from pocket-agent-web-app logo (ImageMagick or macOS sips).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESKTOP="${ROOT}/pocket-agent-desktop-app"
LOGO="${ROOT}/pocket-agent-web-app/src/assets/react-supabase-auth-template-logo.png"
ICON_DIR="${DESKTOP}/src-tauri/icons"

if [[ ! -f "$LOGO" ]]; then
  echo "Logo not found: $LOGO (install pocket-agent-web-app first)"
  exit 1
fi

mkdir -p "$ICON_DIR"

resize() {
  local size="$1"
  local out="$2"
  if command -v magick >/dev/null 2>&1; then
    magick "$LOGO" -resize "${size}x${size}" "$out"
  elif command -v sips >/dev/null 2>&1; then
    sips -z "$size" "$size" "$LOGO" --out "$out" >/dev/null
  else
    echo "Need ImageMagick (magick) or macOS sips to generate icons"
    exit 1
  fi
}

resize 32 "${ICON_DIR}/32x32.png"
resize 128 "${ICON_DIR}/128x128.png"
resize 256 "${ICON_DIR}/128x128@2x.png"
resize 256 "${ICON_DIR}/icon.icns"
resize 256 "${ICON_DIR}/icon.ico"

echo "Icons written to pocket-agent-desktop-app/src-tauri/icons/"
