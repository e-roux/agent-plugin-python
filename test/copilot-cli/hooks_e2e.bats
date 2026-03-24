#!/usr/bin/env bats

# E2E tests -- validate hook behaviour and LSP integration by invoking the real copilot CLI.
#
# Each test:
#   1. Creates an isolated TMPDIR and copies the hook scripts into it under
#      .github/hooks/scripts/ (the standard project-level hooks location).
#   2. Generates a .github/hooks/policy.json hooks config that copilot discovers
#      automatically from *.json files in .github/hooks/.
#   3. For LSP tests: copies lsp.json to .github/lsp.json so copilot picks it up
#      automatically as the repository-level LSP configuration.
#   4. Runs copilot non-interactively from that directory (model: gpt-4.1).
#   5. Asserts hook behaviour by inspecting the audit log written by the scripts
#      (logs go to .github/hooks/logs/ via SCRIPT_DIR resolution) and/or by
#      checking copilot's output for evidence of hook action.
#
# IMPORTANT: These tests make real API calls (gpt-4.1) and take ~30-90s each.

PLUGIN_SRC="$BATS_TEST_DIRNAME/../../copilot-cli"

setup() {
  WORK="$(mktemp -d)"
  mkdir -p "$WORK/.github/hooks/scripts"

  # Copy hook scripts into the project's standard hooks location.
  cp "$PLUGIN_SRC/hooks/scripts/pre-tool.sh"      "$WORK/.github/hooks/scripts/"
  cp "$PLUGIN_SRC/hooks/scripts/session-start.sh" "$WORK/.github/hooks/scripts/"
  chmod +x "$WORK/.github/hooks/scripts/"*.sh

  # Generate a project-level hooks config at .github/hooks/policy.json.
  # Copilot picks up *.json files from .github/hooks/ automatically.
  # cwd:.github/hooks makes the scripts run from there so SCRIPT_DIR resolves
  # to .github/hooks/scripts and logs land at .github/hooks/logs/.
  cat > "$WORK/.github/hooks/policy.json" << 'HOOKSJSON'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "./scripts/session-start.sh",
        "cwd": ".github/hooks",
        "timeoutSec": 10
      }
    ],
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/pre-tool.sh",
        "cwd": ".github/hooks",
        "timeoutSec": 15
      }
    ]
  }
}
HOOKSJSON
}

teardown() {
  rm -rf "$WORK"
}

# Audit log directory (hooks run with cwd=.github/hooks; SCRIPT_DIR=.github/hooks/scripts;
# logs resolve to $SCRIPT_DIR/../logs = .github/hooks/logs).
_log_dir() { echo "$WORK/.github/hooks/logs"; }

# Run copilot non-interactively from WORK with the given prompt.
# Captures both stdout and stderr.
_copilot() {
  cd "$WORK" && timeout 90 copilot \
    --model "gpt-4.1" \
    --disable-builtin-mcps \
    --no-ask-user \
    --allow-all-tools \
    -p "$1" 2>&1
}

# --- session-start hook -------------------------------------------------------

@test "e2e session-start: hook fires when copilot starts" {
  run _copilot "Say hello"
  [ "$status" -eq 0 ]
  # The session-start hook writes an audit entry on every invocation.
  [ -f "$(_log_dir)/session-start.log" ]
  grep -q "session-start fired" "$(_log_dir)/session-start.log"
}

# --- pre-tool hook ------------------------------------------------------------

@test "e2e pre-tool: pip install is denied by hook" {
  run _copilot "You must use the bash tool to execute this exact command and report the output: pip install requests"
  [ "$status" -eq 0 ]
  # The pre-tool hook writes a deny entry for every forbidden command it intercepts.
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "pip install requests" "$(_log_dir)/pre-tool-denied.log"
}

@test "e2e pre-tool: mypy is denied, zmypy guidance shown" {
  run _copilot "You must use the bash tool to execute this exact command and report the output: mypy ."
  [ "$status" -eq 0 ]
  # The pre-tool hook must have written a denial entry for mypy
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "mypy" "$(_log_dir)/pre-tool-denied.log"
}

@test "e2e pre-tool: uv command is allowed by hook" {
  run _copilot "Use the bash tool to run: uv --version"
  [ "$status" -eq 0 ]
  # No deny log entry must exist for uv
  local deny_log
  deny_log="$(_log_dir)/pre-tool-denied.log"
  if [ -f "$deny_log" ]; then
    ! grep -q "uv --version" "$deny_log"
  fi
  # uv actually ran -- its output is visible in copilot's response
  local plain
  plain="$(echo "$output" | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"uv"* ]]
}

# --- LSP integration ----------------------------------------------------------

# _setup_lsp installs the plugin's lsp.json as a repository-level LSP config
# (.github/lsp.json) so copilot auto-discovers it without requiring a full
# plugin install.
_setup_lsp() {
  mkdir -p "$WORK/.github"
  cp "$PLUGIN_SRC/lsp.json" "$WORK/.github/lsp.json"
}

@test "e2e lsp: edit tool works with ruff and zuban lsp servers configured" {
  _setup_lsp

  # Create a Python file with deliberate style violations that ruff would flag:
  #   - missing whitespace around operator (E225)
  #   - unused import (F401)
  cat > "$WORK/sample.py" << 'PYEOF'
import os
x=1
print(x)
PYEOF

  run _copilot "Use the edit tool to fix all PEP 8 style issues in sample.py. Remove unused imports and add spaces around operators."
  [ "$status" -eq 0 ]

  # The edit tool must have modified the file.
  [ -f "$WORK/sample.py" ]

  # ruff LSP diagnostic for E225 (missing whitespace around =) must be resolved.
  local plain
  plain="$(cat "$WORK/sample.py")"
  [[ "$plain" == *"x = 1"* ]]
}

@test "e2e lsp: zuban lsp provides type diagnostics on edit" {
  _setup_lsp

  # Create a Python file with a type annotation so zuban can analyse it.
  cat > "$WORK/typed.py" << 'PYEOF'
def greet(name: str) -> str:
    return "Hello, " + name


result: int = greet("world")
PYEOF

  run _copilot "Use the edit tool to fix the type error in typed.py: the variable 'result' is annotated as int but greet() returns str."
  [ "$status" -eq 0 ]

  # The file must have been edited.
  [ -f "$WORK/typed.py" ]

  # The type annotation on result should be corrected to str.
  local plain
  plain="$(cat "$WORK/typed.py")"
  [[ "$plain" == *"result: str"* ]]
}
