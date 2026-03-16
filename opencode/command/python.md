---
description: "Python development workflow using uv and zmypy. Enforces the uv toolchain: no pip, no direct python, no mypy."
---

# Python Development Workflow

This command sets up your session with the mandatory Python development workflow for this project.

## MANDATORY: Use uv — Never pip or python directly

The `PythonEnforcerPlugin` is active. Direct calls to `python`, `pip`, `virtualenv`, or `mypy` are **blocked**. Use:

| Forbidden | Replacement |
|-----------|-------------|
| `pip install <pkg>` | `uv add <pkg>` |
| `pip install -r requirements.txt` | `uv sync` |
| `python script.py` | `uv run script.py` |
| `python -m pip` | `uv add <pkg>` |
| `python -m venv` | `uv venv` |
| `virtualenv .venv` | `uv venv` |
| `mypy src/` | `zmypy src/` or `uv run zmypy src/` |

---

## Toolchain

| Tool | Command | Purpose |
|------|---------|---------|
| **uv** | `uv run script.py` | Run scripts with inline deps (PEP 723) |
| **uv** | `uv add <pkg>` | Add dependency |
| **uv** | `uv sync` | Sync environment from `pyproject.toml` |
| **uvx** | `uvx <tool>` | Run a tool without installing |
| **ruff** | `uv run ruff format src/` | Format code |
| **ruff** | `uv run ruff check --fix src/` | Lint + auto-fix (includes ANN, TC rules) |
| **zmypy** | `uv run zmypy src/` | Type check via zuban (20-200× faster than mypy) |
| **pytest** | `uv run pytest` | Run tests |
| **make** | `make qa` | Full quality gate (format + lint + typecheck + test) |

---

## Scripts with Inline Dependencies (PEP 723)

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests", "rich"]
# ///

import requests
from rich import print
```

Run with: `uv run script.py` — no virtualenv setup needed.

---

## Project Workflow

```bash
# Create a new project
uv init my-project && cd my-project

# Add dependencies
uv add requests ruff pytest

# Add dev dependencies
uv add --dev ruff pytest zmypy

# Run quality gate
make qa  # fmt → lint → zmypy typecheck → pytest
```

---

## Type Annotations (Required)

All functions **must** have type annotations. `ruff` enforces this via `ANN` rules.

```python
def greet(name: str) -> str:
    return f"Hello, {name}"

def fetch(url: str, timeout: int = 30) -> dict[str, str]:
    ...
```

---

## pyproject.toml Configuration

```toml
[tool.mypy]  # zmypy reads this section
strict = true
ignore_missing_imports = true
check_untyped_defs = true

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "ANN", "TC", "RUF"]
```
