#!/usr/bin/env bash
# Generate Tauri icons from pocket-agent-web-app logo (RGBA PNG + icns/ico).
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

# Tauri CLI produces correct RGBA PNGs, .icns, and .ico (required for compile).
if [[ -f "${DESKTOP}/node_modules/@tauri-apps/cli/package.json" ]]; then
  echo "→ Generating icons via tauri icon"
  (cd "${DESKTOP}" && npm run tauri -- icon "$LOGO" -o src-tauri/icons)
  echo "Icons written to pocket-agent-desktop-app/src-tauri/icons/"
  exit 0
fi

resize_rgba_png() {
  local size="$1"
  local out="$2"
  if command -v magick >/dev/null 2>&1; then
    magick "$LOGO" -background none -alpha on -resize "${size}x${size}" "PNG32:${out}"
  else
    echo "Install desktop deps first (npm install in pocket-agent-desktop-app)"
    echo "or: brew install imagemagick"
    exit 1
  fi
}

echo "→ Generating RGBA PNG icons via ImageMagick (install desktop npm deps for full icns/ico)"
resize_rgba_png 32 "${ICON_DIR}/32x32.png"
resize_rgba_png 128 "${ICON_DIR}/128x128.png"
resize_rgba_png 256 "${ICON_DIR}/128x128@2x.png"

if command -v magick >/dev/null 2>&1; then
  magick "${ICON_DIR}/128x128@2x.png" "${ICON_DIR}/icon.ico"
  # macOS .icns needs iconutil or magick — skip if tauri icon unavailable
  if command -v iconutil >/dev/null 2>&1; then
  tmp_iconset="$(mktemp -d)"
  magick "${ICON_DIR}/128x128@2x.png" -resize 16x16 "${tmp_iconset}/icon_16x16.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 32x32 "${tmp_iconset}/icon_16x16@2x.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 32x32 "${tmp_iconset}/icon_32x32.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 64x64 "${tmp_iconset}/icon_32x32@2x.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 128x128 "${tmp_iconset}/icon_128x128.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 256x256 "${tmp_iconset}/icon_128x128@2x.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 256x256 "${tmp_iconset}/icon_256x256.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 512x512 "${tmp_iconset}/icon_256x256@2x.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 512x512 "${tmp_iconset}/icon_512x512.png"
  magick "${ICON_DIR}/128x128@2x.png" -resize 1024x1024 "${tmp_iconset}/icon_512x512@2x.png"
  iconset_dir="${tmp_iconset}/icon.iconset"
  mkdir -p "$iconset_dir"
  mv "${tmp_iconset}"/icon_*.png "$iconset_dir/"
  iconutil -c icns "$iconset_dir" -o "${ICON_DIR}/icon.icns"
  rm -rf "$tmp_iconset"
  fi
fi

echo "Icons written to pocket-agent-desktop-app/src-tauri/icons/"
