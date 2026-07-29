# Contributing

Thanks for contributing to **scripts** — part of the [Pocket Agent](https://github.com/pocket-agent) ecosystem.

## Guidelines

- Keep scripts POSIX-friendly bash with `set -euo pipefail`.
- Paths assume workspace root = parent of `config/` and `pocket-agent/`.
- Test on macOS when changing `setup-local.sh` or `dev-desktop.sh`.

## Pull requests

1. Branch from `main`.
2. Run changed scripts locally against a full workspace clone.
3. Update `CHANGELOG.md` for user-visible changes.

## License

MIT — see [LICENSE](LICENSE).
