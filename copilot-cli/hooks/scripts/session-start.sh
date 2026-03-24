#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"

INPUT="$(cat)"
CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"

jq -cn '{additionalContext: "## Python / uv Policy Active\n\nDirect `python` or `pip` calls are FORBIDDEN. Use `uv` instead:\n- `uv run script.py` — run a script\n- `uv add <package>` — add a dependency\n- `uvx <tool>` — run a tool\n- `uv run --with <pkg>` — inline dependency"}'

# Write audit log so the hook invocation is verifiable in tests.
mkdir -p "$LOG_DIR" && \
  echo "session-start fired at $(date -u +%Y-%m-%dT%H:%M:%SZ), cwd=${CWD}" >> "$LOG_DIR/session-start.log" \
  || true

exit 0
