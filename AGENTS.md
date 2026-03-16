# Agent instructions

This repository provides a Python development plugin for AI coding agents. The plugin enforces the `uv` toolchain and blocks direct use of `pip`, `python`, `virtualenv`, `mypy`, and `poetry`. Two agents are currently supported: GitHub Copilot CLI and OpenCode.

## Toolchain constraint

Direct use of `python`, `python3`, `pip`, `pip3`, or `venv` is prohibited everywhere in this repository, including in test scripts. Use `uv run`, `uv add`, and `uvx` exclusively.

## Plugin structure

Each agent has its own integration layer:

- **Copilot CLI** — shell hooks (`hooks/scripts/`) configured via `hooks/policy.json`, and a skill (`skill/SKILL.md`) loaded into the agent context.
- **OpenCode** — a TypeScript plugin (`opencode/core.ts`, `opencode/index.ts`) that subscribes to `tool.execute.before` and a command document (`opencode/command/python.md`).

Both enforce the same blocking rules. See README.md for the full resource inventory.

## Development guidelines

- Implement tests before writing implementation code. Know what you are building before you build it.
- Keep the Makefile well organised. Do not add targets without a clear purpose.
- Minimise third-party dependencies. Security is a primary concern.
- Run `make qa` before every commit.

## Testing

### Copilot CLI hooks

Hooks are unit-tested with bats (`test/hooks.bats`) and end-to-end with a real Copilot CLI invocation (`test/hooks_e2e.bats`).

E2E tests must:

- Work from a `TMPDIR` — never from the repository root.
- Copy hook scripts into the temporary directory under `.github/hooks/scripts/` and write a corresponding `policy.json` before invoking `copilot`.
- Use only model `gpt-4.1` (`--model "gpt-4.1"`). This is not negotiable.
- Pass `--disable-builtin-mcps`, `--no-ask-user`, and `--allow-all-tools` for non-interactive execution.
- Pass the prompt via `-p <PROMPT>`.
- Evaluate the outcome from audit logs (`pre-tool-denied.log`, `session-start.log`) and the CLI response.

A hook test that does not invoke the real `copilot` binary is considered failing.

### OpenCode plugin

The rule engine is unit-tested with `bun test` (`test/opencode.test.ts`) and end-to-end with a real OpenCode invocation (`test/opencode_e2e.bats`).

E2E tests must:

- Work from a `TMPDIR`.
- Copy the plugin files into `.opencode/plugins/` in the temporary directory.
- Evaluate denied commands from audit logs (`.opencode/logs/pre-tool-denied.log`).

A plugin test that does not invoke the real `opencode` binary is considered failing.

## References

### GitHub Copilot CLI

- CLI command reference: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference
- Plugin reference: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
- Custom agents configuration: https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Hooks configuration: https://docs.github.com/en/copilot/reference/hooks-configuration

### OpenCode

- Plugin documentation: https://opencode.ai/docs/plugins

### uv

- Scripts with inline dependencies (PEP 723): https://docs.astral.sh/uv/guides/scripts
- Projects: https://docs.astral.sh/uv/guides/projects/
