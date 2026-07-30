# scripts

Local setup and dev helpers for the [Pocket Agent](https://github.com/pocket-agent) workspace.

**GitHub:** [pocket-agent/scripts](https://github.com/pocket-agent/scripts)

## Scripts

| Script | Purpose |
|--------|---------|
| `setup-local.sh` | First-time setup — venv, SDK, deps, env, wizard build |
| `dev-desktop.sh` | Print (or hint) 3-terminal Tauri dev stack |
| `dev-stack.sh` | Print browser-only local stack |
| `init-workspace.sh` | Wrapper for `pocket-agent init` |
| `generate-desktop-icons.sh` | Tauri icons from `pocket-agent/.github/pocket-agent-image.png` |
| `sync-pocket-agent-branding.sh` | Copy logo + README screenshot into each `pocket-agent*` repo `.github/` |

## Prerequisites

Clone [config](https://github.com/pocket-agent/config) and [pocket-agent](https://github.com/pocket-agent/pocket-agent) as siblings first — see [config README](https://github.com/pocket-agent/config#bootstrap-new-machine).

```bash
mkdir -p ~/pocket-agent && cd ~/pocket-agent
git clone https://github.com/pocket-agent/config.git config
git clone https://github.com/pocket-agent/scripts.git scripts
git clone https://github.com/pocket-agent/pocket-agent.git pocket-agent
chmod +x scripts/*.sh
./scripts/setup-local.sh
```

**Desktop dev:** `./scripts/dev-desktop.sh` (agent `:8787`, API `:8788`, Tauri)

**Wizard:** `cd pocket-agent && source .venv/bin/activate && pocket-agent wizard`
