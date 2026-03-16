#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.toolName // empty')"

# Only intercept bash tool calls
if [ "$TOOL_NAME" != "bash" ]; then
  exit 0
fi

TOOL_ARGS_RAW="$(echo "$INPUT" | jq -r '.toolArgs // empty')"
COMMAND="$(echo "$TOOL_ARGS_RAW" | jq -r '.command // empty')"

# Detect direct invocations of python/pip/virtualenv.
# Matches at command start or after a shell operator (; & |).
# Does NOT match when python appears as an argument to another tool (e.g. "uv run python").
FORBIDDEN_PATTERN='(^|[;&|][[:space:]]*)(python3?|pip3?|virtualenv)([[:space:]]|$)'
if echo "$COMMAND" | grep -qE "$FORBIDDEN_PATTERN"; then
  # Write deny audit log (logs/ is gitignored; failure to log must not block the hook).
  mkdir -p "$LOG_DIR" 2>/dev/null \
    && echo "denied at $(date -u +%Y-%m-%dT%H:%M:%SZ): $COMMAND" >> "$LOG_DIR/pre-tool-denied.log" 2>/dev/null \
    || true
  jq -n \
    '{"permissionDecision":"deny","permissionDecisionReason":"Direct python/pip/virtualenv usage is forbidden. Use uv: uv run <script>, uv add <pkg>, uvx <tool>"}'
  exit 0
fi

# Detect direct mypy usage — zmypy (zuban) must be used instead.
# Allows: zmypy, uv run zmypy, uvx zmypy
# Blocks: mypy, python -m mypy (caught above by python pattern)
MYPY_PATTERN='(^|[;&|][[:space:]]*)(mypy)([[:space:]]|$)'
if echo "$COMMAND" | grep -qE "$MYPY_PATTERN"; then
  mkdir -p "$LOG_DIR" 2>/dev/null \
    && echo "denied at $(date -u +%Y-%m-%dT%H:%M:%SZ): $COMMAND" >> "$LOG_DIR/pre-tool-denied.log" 2>/dev/null \
    || true
  jq -n \
    '{"permissionDecision":"deny","permissionDecisionReason":"Direct mypy usage is forbidden. Use zmypy (zuban drop-in replacement): zmypy src/ or uv run zmypy src/"}'
  exit 0
fi

exit 0
