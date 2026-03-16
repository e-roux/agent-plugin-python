# Agent Plugin Python

A GitHub Copilot CLI plugin that enforces a secure, opinionated Python development workflow using **uv** as the package manager and **zmypy** for type checking. 

## Features

### 🚫 Command Interception (OpenCode)
The plugin intercepts dangerous commands and blocks/redirects them:
- **Blocks**: `pip`, `pip3`, `python`, `python3`, `virtualenv`, `mypy`, `poetry`
- **Guidance**: Provides helpful error messages suggesting correct alternatives

### ⚙️ Hooks Integration
Pre-tool hooks enforce the same rules at the Copilot CLI level, preventing unsafe package management commands before they execute.

### 🔍 Type Checking
Built-in support for `zmypy` (zuban) — a 20-200× faster drop-in replacement for mypy with the same strict checking.

### 📦 Full uv Toolchain
- `uv init` — initialize projects
- `uv add` — manage dependencies  
- `uv sync` — sync from `pyproject.toml`
- `uv run` — execute scripts with inline dependencies (PEP 723)
- `uvx` — run tools without installing

## Components

| Component | Purpose |
|-----------|---------|
| **Hooks** | Pre-tool hooks that intercept unsafe commands at the Copilot CLI level |
| **OpenCode Plugin** | TypeScript-based command interception with block rules and guidance messages |
| **Commands** | Copilot command (e.g., `/python`) with documentation and workflow guidance |

## Installation

This plugin is installed as part of the Copilot CLI plugin ecosystem.

## Usage

Once installed, the plugin:
1. Prevents direct use of `pip`, `python`, `virtualenv`, `mypy`, and `poetry`
2. Provides helpful error messages directing users to `uv` equivalents
3. Works seamlessly with `uv run` for PEP 723 scripts and projects

## Example

```bash
# ❌ Blocked
$ copilot "pip install requests"
> Error: pip is forbidden. Use uv instead:
>   uv add <package>            — add dependency to project
>   uv run --with <pkg> <cmd>   — one-shot with inline dep

# ✅ Correct
$ copilot "uv add requests"
> Added requests==2.31.0
```

## Development

Run the full quality gate:
```bash
make qa  # formats, lints, type-checks, and tests
```

Test components individually:
- **Hooks**: `make hooks.test`
- **OpenCode**: `make opencode.test`

## Testing with Copilot CLI

Tests validate end-to-end behavior with the actual Copilot CLI:
```bash
bats test/opencode_e2e.bats  # Full integration tests
```

See `test/opencode_e2e.bats` for examples.
