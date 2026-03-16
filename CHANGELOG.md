# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-16

### Added

- **OpenCode Plugin**: TypeScript-based command interception system that blocks unsafe Python package management commands (`pip`, `virtualenv`, `mypy`, `poetry`, direct `python`)
- **Command Interception Rules**: Comprehensive rule set with:
  - Block rules for forbidden commands with helpful error messages
  - Guidance toward `uv` and `zmypy` alternatives
  - Support for command chaining (`;`, `&&`, `|`)
- **OpenCode Tests**: Full unit test suite (`test/opencode.test.ts`) with 25+ test cases covering all rule patterns
- **End-to-End Tests**: BATS-based integration tests (`test/opencode_e2e.bats`) validating real Copilot CLI behavior
- **Python Command**: OpenCode command documentation (`opencode/command/python.md`) with workflow reference
- **Makefile Support**: `opencode.test` target and bun dependency installation

### Changed

- **Makefile**: Added `BUN` variable and `opencode.test` target to test suite; updated `.PHONY` declarations
- **gitignore**: Updated to exclude `.opencode/logs/` and `node_modules/` artifacts

## [0.1.0] - 2026-03-10

### Added

- Initial project structure
- Hooks-based command enforcement at Copilot CLI level
- AGENTS.md configuration for plugin discovery
- plugin.json metadata

[Unreleased]: https://github.com/e-roux/agent-plugin-python/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/e-roux/agent-plugin-python/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/e-roux/agent-plugin-python/releases/tag/v0.1.0
