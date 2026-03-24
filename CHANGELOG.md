# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-03-17

### Added

- **LSP integration** (`copilot-cli/lsp.json`): repository-level LSP server configuration for the copilot-cli plugin with full working configurations for:
  - **ruff** (`ruff server`) — linting, formatting, and import-organisation diagnostics for `.py` / `.pyi` files.
  - **zuban** (`zuban server`) — mypy-compatible, Rust-based type-checking diagnostics for `.py` / `.pyi` files, 20-200× faster than mypy.
- `plugin.json` now references `lsp.json` via the `lspServers` field so both LSP servers are activated automatically on plugin install.
- **LSP unit tests** (`test/copilot-cli/hooks.bats`): JSON structure validation tests for `lsp.json` (9 new tests).
- **LSP E2E tests** (`test/copilot-cli/hooks_e2e.bats`): two real copilot CLI invocations (model: `gpt-4.1`) that verify:
  1. The `edit` tool works correctly with ruff and zuban LSP servers active and fixes ruff E225 / F401 violations.
  2. The `edit` tool correctly resolves a zuban type-annotation mismatch.

### Added

- **opencode plugin**: proactive policy injection via three new hooks — `experimental.chat.system.transform` (policy in system prompt), `tool.definition` (bash tool description addendum), `experimental.session.compacting` (policy preserved across compaction).

## [0.3.0] - 2026-03-16

### Changed

- **Monorepo structure**: Moved all resources into agent-specific subdirectories:
  - `copilot-cli/` — plugin manifest, hooks, and skill (install via `e-roux/agent-plugin-python:copilot-cli`)
  - `opencode/` — npm package (`opencode-python-enforcer`)
  - `test/copilot-cli/` and `test/opencode/` — agent-scoped test directories
- **Version sync**: `opencode/package.json` is now the version source of truth; `copilot-cli/plugin.json` must match. Enforced by `make version.check` (runs as part of `make qa`).
- **Makefile**: Renamed `hooks.test` → `copilot-cli.test`; updated all paths; added `version.check` and `publish` targets; added `distclean` for build artifact cleanup.

### Added

- `opencode/package.json` — npm manifest for the OpenCode plugin (`opencode-python-enforcer`)
- `opencode/tsconfig.json` — TypeScript compiler configuration (ESNext/bundler)
- `make publish` — creates a GitHub Release tagged `v<VERSION>` with CHANGELOG as notes

### Fixed

- OpenCode plugin was not publishable as an npm package (missing `package.json`)
- Test BATS and TypeScript files had stale relative paths after directory reorganisation

## [0.2.0] - 2026-03-16

### Added

- **OpenCode Plugin**: TypeScript-based command interception system that blocks unsafe Python package management commands (`pip`, `virtualenv`, `mypy`, `poetry`, direct `python`)
- **Command Interception Rules**: Comprehensive rule set with block rules and guidance toward `uv` and `zmypy` alternatives
- **OpenCode Tests**: Full unit test suite (`test/opencode.test.ts`) with 25+ test cases
- **End-to-End Tests**: BATS-based integration tests validating real Copilot CLI behaviour
- **Python Command**: OpenCode command documentation (`opencode/command/python.md`)
- **Makefile Support**: `opencode.test` target and bun dependency

### Changed

- **Makefile**: Added `BUN` variable and `opencode.test` target; updated `.PHONY` declarations
- **gitignore**: Updated to exclude `.opencode/logs/` and `node_modules/`

## [0.1.0] - 2026-03-10

### Added

- Initial project structure
- Hooks-based command enforcement at Copilot CLI level
- AGENTS.md configuration for plugin discovery
- plugin.json metadata

[Unreleased]: https://github.com/e-roux/agent-plugin-python/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/e-roux/agent-plugin-python/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/e-roux/agent-plugin-python/compare/v0.3.0...v0.3.1
[0.2.0]: https://github.com/e-roux/agent-plugin-python/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/e-roux/agent-plugin-python/releases/tag/v0.1.0
