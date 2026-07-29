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

need npm
need bun

find_python() {
  local cmd ver
  for cmd in python3.13 python3.12; do
    if command -v "$cmd" >/dev/null 2>&1; then
      if "$cmd" -c 'import sys; assert sys.version_info >= (3, 12)' 2>/dev/null; then
        echo "$cmd"
        return 0
      fi
    fi
  done
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c 'import sys; assert sys.version_info >= (3, 12)' 2>/dev/null; then
      echo python3
      return 0
    fi
    ver="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
    echo "Found python3 ${ver} but pocket-agent requires Python >= 3.12."
  else
    echo "python3 not found."
  fi
  echo "Install: brew install python@3.12"
  return 1
}

PYTHON="$(find_python)" || exit 1
echo "Using ${PYTHON} ($(${PYTHON} --version))"

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
if [[ -d .venv ]] && ! .venv/bin/python -c 'import sys; assert sys.version_info >= (3, 12)' 2>/dev/null; then
  echo "Removing .venv (Python < 3.12 — recreate with ${PYTHON})"
  rm -rf .venv
fi
if [[ ! -d .venv ]]; then
  "${PYTHON}" -m venv .venv
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
