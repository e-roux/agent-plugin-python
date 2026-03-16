# agent-plugin-python

An opinionated Python development plugin for AI coding agents. It enforces the `uv` toolchain (no direct `pip`, `python`, `virtualenv`, `mypy`, or `poetry` calls) and provides workflow guidance through agent-specific integration points.

Two agents are currently supported:

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference) — installed via GitHub subdir
- [OpenCode](https://opencode.ai/docs/plugins) — published as an npm package

---

## Repository layout

This repository is organised as a monorepo. Each agent has its own subdirectory:

```
agent-plugin-python/
├── copilot-cli/          GitHub Copilot CLI plugin
│   ├── plugin.json       Plugin manifest
│   ├── hooks/            Hook configuration and shell scripts
│   └── skill/            Skill definition and assets
├── opencode/             OpenCode npm package
│   ├── package.json      npm manifest (version source of truth)
│   ├── tsconfig.json     TypeScript configuration
│   ├── core.ts           Rule engine (pure, testable)
│   ├── index.ts          Plugin entry point
│   └── command/          Command documentation
└── test/
    ├── copilot-cli/      Copilot CLI hook tests
    └── opencode/         OpenCode plugin tests
```

---

## Policy

All agents enforce the same rule set. Direct invocations of `pip`, `pip3`, `python`, `python3`, `python -m pip`, `python -m venv`, `virtualenv`, `mypy`, and `poetry` are blocked. The required alternatives are:

| Forbidden | Replacement |
|-----------|-------------|
| `pip install <pkg>` | `uv add <pkg>` |
| `pip install -r requirements.txt` | `uv sync` |
| `python script.py` | `uv run script.py` |
| `python -m pip` | `uv add <pkg>` |
| `python -m venv` | `uv venv` |
| `virtualenv .venv` | `uv venv` |
| `mypy src/` | `uv run zmypy src/` |
| `poetry install` | `uv sync` |

Commands invoked through `uv run`, `uvx`, or `zmypy` directly are allowed.

---

## Installation

### GitHub Copilot CLI

Install the plugin from this repository's `copilot-cli/` subdirectory:

```bash
copilot plugin install e-roux/agent-plugin-python:copilot-cli
```

### OpenCode

Add the package to your `opencode.json` configuration:

```json
{
  "plugin": ["opencode-python-enforcer"]
}
```

OpenCode installs it automatically via Bun at startup.

---

## Resources by agent

### GitHub Copilot CLI (`copilot-cli/`)

The Copilot CLI integration is hook-based. Hooks run as shell scripts before tool execution and at session start. The skill provides workflow instructions loaded into the agent's context.

| Resource | Path | Role |
|----------|------|------|
| Plugin manifest | `copilot-cli/plugin.json` | Declares skills and hooks paths |
| Hook configuration | `copilot-cli/hooks/policy.json` | Registers `sessionStart` and `preToolUse` hooks |
| Pre-tool hook | `copilot-cli/hooks/scripts/pre-tool.sh` | Intercepts bash tool calls; denies forbidden commands |
| Session-start hook | `copilot-cli/hooks/scripts/session-start.sh` | Displays policy banner at session start; writes audit log |
| Skill definition | `copilot-cli/skill/SKILL.md` | Loaded into agent context; describes uv workflow and tool table |
| Makefile guide | `copilot-cli/skill/assets/python.md` | Makefile template for uv-based Python projects |
| pytest config | `copilot-cli/skill/assets/conftest.py` | Auto-marker configuration for unit/integration/e2e/benchmark |
| Project template | `copilot-cli/skill/assets/pyproject.toml.template` | uv project configuration template |
| Ruff config | `copilot-cli/skill/assets/ruff.toml` | Linter and formatter configuration |
| Build guide | `copilot-cli/skill/resources/build.md` | uv build backend reference |
| Script guide | `copilot-cli/skill/resources/scripts.md` | PEP 723 inline-dependency script reference |

### OpenCode (`opencode/`)

The OpenCode integration is a TypeScript npm package that hooks into the `tool.execute.before` event. The rule logic is isolated in `core.ts` and is independently unit-tested.

| Resource | Path | Role |
|----------|------|------|
| npm manifest | `opencode/package.json` | Package definition; version source of truth |
| TypeScript config | `opencode/tsconfig.json` | Compiler options for Bun/ESNext |
| Rule engine | `opencode/core.ts` | Pure TypeScript: `BlockRule`, `intercept()`, `defaultRules` |
| Plugin entry point | `opencode/index.ts` | Subscribes to `tool.execute.before`; calls `intercept()` on bash input |
| Command documentation | `opencode/command/python.md` | Rendered when the user invokes the `/python` command |

---

## Version synchronisation

The version in `opencode/package.json` is the single source of truth. The version in `copilot-cli/plugin.json` must match it at all times.

```bash
make version.check   # verifies both files have the same version
make qa              # runs version.check as part of the quality gate
```

To release a new version:
1. Update the version in both `opencode/package.json` and `copilot-cli/plugin.json`.
2. Add an entry to `CHANGELOG.md`.
3. Run `make qa`.
4. Commit, push, open a PR, merge.
5. Run `make publish` to create the GitHub Release.

---

## Tests

Each agent has a two-level test suite: isolated unit tests and end-to-end tests that invoke the real CLI.

| Test file | Runner | Scope | Agent |
|-----------|--------|-------|-------|
| `test/copilot-cli/hooks.bats` | bats | Unit — hook script logic | Copilot CLI |
| `test/copilot-cli/hooks_e2e.bats` | bats + copilot | E2E — real CLI invocation | Copilot CLI |
| `test/opencode/core.test.ts` | bun test | Unit — rule engine logic | OpenCode |
| `test/opencode/e2e.bats` | bats + opencode | E2E — real CLI invocation | OpenCode |

E2E tests always run from a temporary directory. Hook scripts and plugin files are copied into the temporary directory before the CLI is invoked.

---

## Development

```bash
make sync              # install dependencies (bats, shellcheck, jq, bun)
make qa                # full quality gate: version.check + fmt + lint + typecheck + test
make copilot-cli.test  # hook unit and e2e tests only
make opencode.test     # TypeScript unit and e2e tests only
make publish           # create GitHub Release for current version
```
