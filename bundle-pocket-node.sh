#!/usr/bin/env bash
# Stage a portable Pocket Node tree for Tauri (macOS arm64 build host).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="${ROOT}/pocket-agent"
SDK_PY="${ROOT}/pocket-agent-sdk/python"
WEB="${ROOT}/pocket-agent-web-app"
DESKTOP="${ROOT}/pocket-agent-desktop-app"
OUT="${DESKTOP}/src-tauri/resources/pocket-node"

find_python() {
  local candidates=(python3.13 python3.12 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.13)
  for cmd in "${candidates[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1 && "$cmd" -c 'import sys; assert sys.version_info >= (3, 12)' 2>/dev/null; then
      echo "$cmd"
      return 0
    fi
  done
  echo "Python >= 3.12 required for bundle"
  return 1
}

echo "→ Bundle Pocket Node into ${OUT}"
rm -rf "${OUT}"
mkdir -p "${OUT}/app" "${OUT}/web-dist"

PYTHON="$(find_python)"

echo "→ Copy agent source"
rsync -a \
  --exclude '.venv' \
  --exclude '.git' \
  --exclude 'data/logs' \
  --exclude 'data/cache/*' \
  --exclude 'data/working' \
  --exclude 'data/backup' \
  --exclude 'data/queue/*' \
  --exclude 'tests' \
  "${AGENT}/" "${OUT}/app/"

mkdir -p "${OUT}/app/data/cache" "${OUT}/app/data/logs" "${OUT}/app/data/queue"
touch "${OUT}/app/data/cache/.gitkeep"

echo "→ SDK (Python) for portable editable install"
mkdir -p "${OUT}/sdk-repo"
cp "${ROOT}/pocket-agent-sdk/README.md" "${OUT}/sdk-repo/"
rsync -a "${ROOT}/pocket-agent-sdk/python/" "${OUT}/sdk-repo/python/"

echo "→ Web UI dist"
if [[ ! -f "${WEB}/dist/index.html" ]]; then
  echo "Web dist missing. Run: cd pocket-agent-web-app && VITE_API_BASE_URL=http://127.0.0.1:8787 VITE_AUTH_MODE=none bun run build"
  exit 1
fi
rsync -a "${WEB}/dist/" "${OUT}/web-dist/"

echo "→ Python venv (--copies)"
"${PYTHON}" -m venv --copies "${OUT}/venv"
# shellcheck source=/dev/null
source "${OUT}/venv/bin/activate"
pip install -q -U pip wheel hatchling
pip install -q -e "${OUT}/sdk-repo/python"
pip install -q -e "${OUT}/app"

cat > "${OUT}/app/.env" <<'EOF'
AUTH_MODE=none
LOG_LEVEL=INFO
EOF

cat > "${OUT}/app/config/settings.yaml" <<'EOF'
agent:
  name: pocket-agent

logging:
  level: INFO

http:
  host: 127.0.0.1
  port: 8787
  serve_static: true
  static_dir: ../web-dist
  allowed_origins:
    - http://127.0.0.1:8787
    - http://localhost:8787
    - tauri://localhost
    - http://tauri.localhost

automation:
  allowed_scripts: []
EOF

cat > "${OUT}/run-serve.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BUNDLE_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${HOME}/.pocket-agent/logs"
mkdir -p "${LOG_DIR}"
LOG="${LOG_DIR}/bundle-serve.log"
export AUTH_MODE=none
export POCKET_AGENT_BUNDLE=1
echo "=== pocket-agent bundle serve $(date) ===" >>"${LOG}"
cd "${BUNDLE_ROOT}/app"
exec "${BUNDLE_ROOT}/venv/bin/pocket-agent" serve >>"${LOG}" 2>&1
EOF
chmod +x "${OUT}/run-serve.sh"

echo "✓ Pocket Node bundle ready ($(du -sh "${OUT}" | awk '{print $1}'))"
