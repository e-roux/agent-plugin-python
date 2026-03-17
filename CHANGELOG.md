# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-03-17

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

[Unreleased]: https://github.com/e-roux/agent-plugin-python/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/e-roux/agent-plugin-python/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/e-roux/agent-plugin-python/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/e-roux/agent-plugin-python/releases/tag/v0.1.0
