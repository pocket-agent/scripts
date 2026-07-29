#!/usr/bin/env bash
# Print local dev stack commands (all-local profile).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"

cat <<EOF
Pocket Agent — local dev stack

Prerequisites:
  - GOOGLE_CLIENT_ID in pocket-agent-web-app/.env.local, pocket-agent-api-app/.dev.vars, pocket-agent/.env
  - GEMINI_API_KEY in pocket-agent/.env (for agent LLM)

Terminal 1 — Pocket Node (agent :8787)
  cd ${AGENT}
  source .venv/bin/activate 2>/dev/null || true
  pocket-agent serve

Terminal 2 — API worker (:8788)
  cd ${ROOT}/pocket-agent-api-app
  cp -n .env.example .dev.vars 2>/dev/null || true
  npm run dev

Terminal 3 — Web UI (:5173)
  cd ${ROOT}/pocket-agent-web-app
  cp -n .env.example .env.local 2>/dev/null || true
  bun run dev

URLs:
  Web:   http://localhost:5173
  API:   http://localhost:8788/health
  Agent: http://127.0.0.1:8787/health

Setup wizard: pocket-agent wizard
Desktop dev:    ./scripts/dev-desktop.sh
Full setup:     ./scripts/setup-local.sh
Docs: docs/WORKSPACE_LAYOUT.md
EOF