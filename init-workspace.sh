#!/usr/bin/env bash
# Install pocket-agent modules as sibling projects (latest GitHub release).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"
cd "$ROOT"

ONLY="${1:-all}"
FORCE="${2:-}"

if command -v pocket-agent >/dev/null 2>&1; then
  ARGS=(init --only "$ONLY")
  if [[ "$FORCE" == "--force" ]]; then
    ARGS+=(--force)
  fi
  exec pocket-agent "${ARGS[@]}"
fi

if [[ -d "${AGENT}/.venv" ]]; then
  exec "${AGENT}/.venv/bin/python" -m pocket_agent.cli.init_modules --only "$ONLY" ${FORCE:+"--force"}
fi

exec python3 -m pocket_agent.cli.init_modules --only "$ONLY" ${FORCE:+"--force"}