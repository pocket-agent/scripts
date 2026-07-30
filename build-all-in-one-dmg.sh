#!/usr/bin/env bash
# Build all-in-one Pocket Agent macOS DMG (desktop + bundled Pocket Node + web UI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"
WEB="${ROOT}/pocket-agent-web-app"
SDK="${ROOT}/pocket-agent-sdk"
DESKTOP="${ROOT}/pocket-agent-desktop-app"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }
}

need npm
need cargo
if command -v bun >/dev/null 2>&1; then
  RUN_JS="bun"
else
  need node
  RUN_JS="npm"
fi

echo "═══════════════════════════════════════════════"
echo " Pocket Agent — all-in-one DMG build"
echo " Workspace: ${ROOT}"
echo "═══════════════════════════════════════════════"

echo "→ SDK"
if [[ -f "${SDK}/package.json" ]]; then
  (cd "${SDK}" && npm install -q && npm run build)
fi

echo "→ Web app (desktop profile — API on Pocket Node :8787)"
(
  cd "${WEB}"
  export VITE_API_BASE_URL=http://127.0.0.1:8787
  export VITE_AUTH_MODE=none
  export VITE_CONNECTION_PROFILE=all-local
  if [[ "$RUN_JS" == "bun" ]]; then
    bun install
    bun run build
  else
    npm install
    npm run build
  fi
)

echo "→ Ensure agent dev venv exists (for bundle script deps check)"
if [[ ! -x "${AGENT}/.venv/bin/pip" ]]; then
  echo "Run ./scripts/setup-local.sh first (Python venv in pocket-agent/)"
  exit 1
fi

echo "→ Bundle Pocket Node into desktop resources"
bash "${ROOT}/scripts/bundle-pocket-node.sh"

echo "→ Icons (if missing)"
if [[ ! -f "${DESKTOP}/src-tauri/icons/icon.icns" ]]; then
  if [[ -x "${ROOT}/scripts/generate-desktop-icons.sh" ]]; then
    bash "${ROOT}/scripts/generate-desktop-icons.sh"
  else
    echo "Warning: no icon.icns — tauri build may fail"
  fi
fi

echo "→ Tauri build"
(
  cd "${DESKTOP}"
  npm install
  npm run build
)

DMG_DIR="${DESKTOP}/src-tauri/target/release/bundle/dmg"
RELEASE_DIR="${DESKTOP}/release"
echo ""
echo "═══════════════════════════════════════════════"
if [[ -d "${DMG_DIR}" ]]; then
  mkdir -p "${RELEASE_DIR}"
  cp "${DMG_DIR}"/*.dmg "${RELEASE_DIR}/" 2>/dev/null || true
  echo " Done. DMG artifacts:"
  ls -lh "${RELEASE_DIR}"/*.dmg 2>/dev/null || ls -la "${DMG_DIR}"
elif [[ -d "${RELEASE_DIR}" ]] && ls "${RELEASE_DIR}"/*.dmg 1>/dev/null 2>&1; then
  echo " Done. DMG copied to:"
  ls -lh "${RELEASE_DIR}"/*.dmg
else
  echo " Build finished — check ${DESKTOP}/src-tauri/target/release/bundle/"
fi
echo "═══════════════════════════════════════════════"
