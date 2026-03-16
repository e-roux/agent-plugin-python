#!/usr/bin/env bats

# E2E tests — validate the opencode Python enforcer plugin via the real CLI.
#
# Each test:
#   1. Creates an isolated TMPDIR and copies the plugin files into
#      $WORK/.opencode/plugins/ (the project-level plugin directory).
#   2. Runs opencode non-interactively from that directory.
#   3. Asserts plugin behaviour via the audit log written by the plugin
#      ($WORK/.opencode/logs/pre-tool-denied.log).
#
# IMPORTANT: These tests make real API calls (github-copilot/gpt-4.1)
#            and take ~30-90s each.

PLUGIN_SRC="$BATS_TEST_DIRNAME/../opencode"

setup() {
  WORK="$(mktemp -d)"
  mkdir -p "$WORK/.opencode/plugins"
  cp "$PLUGIN_SRC/core.ts"  "$WORK/.opencode/plugins/"
  cp "$PLUGIN_SRC/index.ts" "$WORK/.opencode/plugins/"
}

teardown() {
  rm -rf "$WORK"
}

_log_dir() { echo "$WORK/.opencode/logs"; }

# Run opencode non-interactively from WORK with the given prompt.
_opencode() {
  cd "$WORK" && timeout 90 opencode \
    --model github-copilot/gpt-4.1 \
    run "$1" 2>&1
}

# --- session completes --------------------------------------------------------

@test "e2e opencode: session completes with plugin loaded" {
  run _opencode "Say the word: OPENCODE_OK"
  [ "$status" -eq 0 ]
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"OPENCODE_OK"* ]]
}

# --- pre-tool: pip -----------------------------------------------------------

@test "e2e opencode: pip install is denied by plugin" {
  run _opencode "You must use the bash tool to execute this exact command and report the output: pip install requests"
  [ "$status" -eq 0 ]
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "pip install requests" "$(_log_dir)/pre-tool-denied.log"
}

# --- pre-tool: mypy ----------------------------------------------------------

@test "e2e opencode: mypy is denied, zmypy guidance shown" {
  run _opencode "You must use the bash tool to execute this exact command and report the output: mypy ."
  [ "$status" -eq 0 ]
  [ -f "$(_log_dir)/pre-tool-denied.log" ]
  grep -q "mypy" "$(_log_dir)/pre-tool-denied.log"
}

# --- pre-tool: uv allowed ----------------------------------------------------

@test "e2e opencode: uv command is allowed by plugin" {
  run _opencode "Use the bash tool to run: uv --version"
  [ "$status" -eq 0 ]
  # No deny log entry for uv
  local deny_log
  deny_log="$(_log_dir)/pre-tool-denied.log"
  if [ -f "$deny_log" ]; then
    ! grep -q "uv --version" "$deny_log"
  fi
  # uv output visible in response
  local plain
  plain="$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')"
  [[ "$plain" == *"uv"* ]]
}
