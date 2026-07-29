#!/usr/bin/env bash
# First-time local setup — agent venv, module deps, env templates, desktop icons.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"

echo "Pocket Agent — local setup"
echo "Workspace: ${ROOT}"
echo ""

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

need python3
need npm
need bun

if [[ "${SETUP_DESKTOP:-1}" == "1" ]]; then
  if ! command -v cargo >/dev/null 2>&1; then
    echo "Rust/cargo not found. Install from https://rustup.rs for Tauri desktop."
    echo "Or run with SETUP_DESKTOP=0 to skip desktop checks."
    exit 1
  fi
fi

echo "→ Shared SDK (TypeScript build)"
if [[ -f "${ROOT}/pocket-agent-sdk/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-sdk" && npm install -q && npm run build)
fi

echo "→ Python agent"
cd "${AGENT}"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck source=/dev/null
source .venv/bin/activate
pip install -q -U pip
if [[ -d "${ROOT}/pocket-agent-sdk/python" ]]; then
  pip install -q -e "${ROOT}/pocket-agent-sdk/python"
fi
pip install -q -e ".[dev]"

echo "→ Workspace config"
if [[ ! -f "${ROOT}/config/user-setup.yaml" ]]; then
  pocket-agent setup
fi

echo "→ Module dependencies"
if [[ -f "${ROOT}/pocket-agent-web-app/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-web-app" && bun install)
fi
if [[ -f "${ROOT}/pocket-agent-api-app/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-api-app" && npm install)
fi
if [[ -f "${ROOT}/pocket-agent-desktop-app/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-desktop-app" && npm install)
fi
if [[ -f "${ROOT}/pocket-agent-cli/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-cli" && npm install)
fi
if [[ -f "${ROOT}/pocket-agent-wizard/package.json" ]]; then
  (cd "${ROOT}/pocket-agent-wizard" && bun install)
fi

echo "→ Env templates"
pocket-agent bootstrap --icons || true

if [[ -f "${ROOT}/pocket-agent-wizard/package.json" ]] && [[ ! -f "${ROOT}/pocket-agent-wizard/dist/index.html" ]]; then
  echo "→ Setup wizard UI"
  (cd "${ROOT}/pocket-agent-wizard" && bun install && bun run build)
fi

if [[ "${SETUP_DESKTOP:-1}" == "1" ]]; then
  echo "→ Desktop icons"
  "${ROOT}/scripts/generate-desktop-icons.sh" || true
fi

echo ""
echo "Setup complete."
echo ""
"${ROOT}/scripts/dev-desktop.sh" --hint-only
