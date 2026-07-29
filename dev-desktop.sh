#!/usr/bin/env bash
# Local dev with Tauri desktop (agent + API + desktop shell; web Vite started by Tauri).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"

HINT_ONLY=0
if [[ "${1:-}" == "--hint-only" ]]; then
  HINT_ONLY=1
fi

print_stack() {
  cat <<EOF
Pocket Agent — local desktop dev

Prerequisites:
  - GEMINI_API_KEY in pocket-agent/.env
  - GOOGLE_CLIENT_ID in pocket-agent/.env, pocket-agent-web-app/.env.local, pocket-agent-api-app/.dev.vars
  - Rust toolchain (cargo) for Tauri

Terminal 1 — Pocket Node (:8787)
  cd ${AGENT}
  source .venv/bin/activate
  pocket-agent serve

Terminal 2 — API worker (:8788)
  cd ${ROOT}/pocket-agent-api-app
  npm run dev

Terminal 3 — Desktop app (starts web Vite on :5173, opens Tauri window)
  cd ${ROOT}/pocket-agent-desktop-app
  npm run dev

First-time setup: ${ROOT}/scripts/setup-local.sh
Wizard: cd ${AGENT} && pocket-agent wizard

URLs:
  Desktop loads: http://localhost:5173
  API health:    http://localhost:8788/health
  Agent health:  http://127.0.0.1:8787/health
EOF
}

if [[ "$HINT_ONLY" == "1" ]]; then
  print_stack
  exit 0
fi

print_stack
