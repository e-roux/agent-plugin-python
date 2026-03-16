# Agent instructions

This repository is a monorepo providing a Python development plugin for AI coding agents. It enforces the `uv` toolchain and blocks direct use of `pip`, `python`, `virtualenv`, `mypy`, and `poetry`. Two agents are currently supported: GitHub Copilot CLI and OpenCode.

## Repository structure

```
agent-plugin-python/
├── copilot-cli/     GitHub Copilot CLI plugin (plugin.json, hooks/, skill/)
├── opencode/        OpenCode npm package (package.json, core.ts, index.ts)
└── test/
    ├── copilot-cli/ Tests for the Copilot CLI integration
    └── opencode/    Tests for the OpenCode integration
```

## Toolchain constraint

Direct use of `python`, `python3`, `pip`, `pip3`, or `venv` is prohibited everywhere in this repository, including in test scripts. Use `uv run`, `uv add`, and `uvx` exclusively.

## Version synchronisation

`opencode/package.json` is the version source of truth. `copilot-cli/plugin.json` must carry the same version. The `make version.check` target enforces this and is part of `make qa`. Never commit with mismatched versions.

## Development guidelines

- Implement tests before writing implementation code.
- Keep the Makefile well organised. Do not add targets without a clear purpose.
- Minimise third-party dependencies. Security is a primary concern.
- Run `make qa` before every commit. `make qa` runs `version.check + check + test`.

## Testing

### Copilot CLI hooks (`copilot-cli/`)

Hooks are unit-tested with bats (`test/copilot-cli/hooks.bats`) and end-to-end with a real Copilot CLI invocation (`test/copilot-cli/hooks_e2e.bats`).

E2E tests must:

- Work from a `TMPDIR` — never from the repository root.
- Copy hook scripts into the temporary directory under `.github/hooks/scripts/` and write a corresponding `policy.json` before invoking `copilot`.
- Use only model `gpt-4.1` (`--model "gpt-4.1"`). This is not negotiable.
- Pass `--disable-builtin-mcps`, `--no-ask-user`, and `--allow-all-tools` for non-interactive execution.
- Pass the prompt via `-p <PROMPT>`.
- Evaluate the outcome from audit logs (`pre-tool-denied.log`, `session-start.log`) and the CLI response.

A hook test that does not invoke the real `copilot` binary is considered failing.

### OpenCode plugin (`opencode/`)

The rule engine is unit-tested with `bun test` (`test/opencode/core.test.ts`) and end-to-end with a real OpenCode invocation (`test/opencode/e2e.bats`).

E2E tests must:

- Work from a `TMPDIR`.
- Copy `core.ts` and `index.ts` into `.opencode/plugins/` in the temporary directory.
- Evaluate denied commands from `.opencode/logs/pre-tool-denied.log`.

A plugin test that does not invoke the real `opencode` binary is considered failing.

## Publishing

Run `make publish` after merging a release PR. This creates a GitHub Release tagged `v<VERSION>` using the CHANGELOG as release notes. The OpenCode package is distributed via npm as `opencode-python-enforcer`; publish separately with `bun publish` inside `opencode/` when ready to push to the npm registry.

## References

### GitHub Copilot CLI

- CLI command reference: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference
- Plugin reference: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
- Creating a plugin: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating
- Custom agents configuration: https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Hooks configuration: https://docs.github.com/en/copilot/reference/hooks-configuration

### OpenCode

- Plugin documentation: https://opencode.ai/docs/plugins

### uv

- Scripts with inline dependencies (PEP 723): https://docs.astral.sh/uv/guides/scripts
- Projects: https://docs.astral.sh/uv/guides/projects/
