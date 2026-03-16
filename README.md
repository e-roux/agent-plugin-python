# agent-plugin-python

An opinionated Python development plugin for AI coding agents. It enforces the `uv` toolchain (no direct `pip`, `python`, `virtualenv`, or `mypy` calls) and provides workflow guidance through agent-specific integration points.

Two agents are currently supported:

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)
- [OpenCode](https://opencode.ai/docs/plugins)

---

## Policy

All agents enforce the same rule set: direct invocations of `pip`, `pip3`, `python`, `python3`, `python -m pip`, `python -m venv`, `virtualenv`, `mypy`, and `poetry` are blocked. The required alternatives are:

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

## Resources by agent

### GitHub Copilot CLI

The Copilot CLI integration is hook-based. Hooks run as shell scripts before tool execution and at session start. The skill provides workflow instructions loaded into the agent's context.

| Resource | Path | Role |
|----------|------|------|
| Plugin manifest | `plugin.json` | Declares skills and hooks paths |
| Hook configuration | `hooks/policy.json` | Registers `sessionStart` and `preToolUse` hooks |
| Pre-tool hook | `hooks/scripts/pre-tool.sh` | Intercepts bash tool calls; denies forbidden commands |
| Session-start hook | `hooks/scripts/session-start.sh` | Displays policy banner at session start; writes audit log |
| Skill definition | `skill/SKILL.md` | Loaded into agent context; describes uv workflow and tool table |
| Makefile guide | `skill/assets/python.md` | Makefile template for uv-based Python projects |
| pytest config | `skill/assets/conftest.py` | Auto-marker configuration for unit/integration/e2e/benchmark |
| Project template | `skill/assets/pyproject.toml.template` | uv project configuration template |
| Ruff config | `skill/assets/ruff.toml` | Linter and formatter configuration |
| Build guide | `skill/resources/build.md` | uv build backend reference |
| Script guide | `skill/resources/scripts.md` | PEP 723 inline-dependency script reference |

The pre-tool hook (`hooks/scripts/pre-tool.sh`) reads the `tool` and `input` fields from the Copilot CLI hook payload. For bash tool calls it tests the command string against a set of patterns using extended regex:

```
(^|[;&|][[:space:]]*)( python3?|pip3?|virtualenv|mypy|poetry )([[:space:]]|$)
```

When a match is found it returns a JSON deny decision and appends a timestamped entry to `hooks/logs/pre-tool-denied.log`.

### OpenCode

The OpenCode integration is a TypeScript plugin that hooks into the `tool.execute.before` event. The rule logic is isolated in `opencode/core.ts` and is independently unit-tested.

| Resource | Path | Role |
|----------|------|------|
| Rule engine | `opencode/core.ts` | Pure TypeScript: `BlockRule`, `RewriteRule`, `intercept()`, `defaultRules` |
| Plugin entry point | `opencode/index.ts` | Subscribes to `tool.execute.before`; calls `intercept()` on bash tool input |
| Command documentation | `opencode/command/python.md` | Rendered when the user invokes the `/python` command |

The plugin is loaded from `.opencode/plugins/` (project-level) or `~/.config/opencode/plugins/` (global). It logs denied commands to `.opencode/logs/pre-tool-denied.log`.

---

## Tests

Each agent has a two-level test suite: isolated unit tests and end-to-end tests that invoke the real CLI.

| Test file | Runner | Scope | Agent |
|-----------|--------|-------|-------|
| `test/hooks.bats` | bats | Unit — hook script logic | Copilot CLI |
| `test/hooks_e2e.bats` | bats + copilot | E2E — real CLI invocation | Copilot CLI |
| `test/opencode.test.ts` | bun test | Unit — rule engine logic | OpenCode |
| `test/opencode_e2e.bats` | bats + opencode | E2E — real CLI invocation | OpenCode |

E2E tests always run from a temporary directory. Hook scripts and plugin files are copied into the temporary directory before the CLI is invoked.

---

## Development

```bash
make sync          # install dependencies (bats, shellcheck, jq, bun)
make qa            # full quality gate: fmt + lint + typecheck + test
make hooks.test    # hook unit and e2e tests
make opencode.test # TypeScript unit and e2e tests
```
