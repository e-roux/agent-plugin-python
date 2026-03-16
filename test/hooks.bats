#!/usr/bin/env bats

SCRIPTS_DIR="$BATS_TEST_DIRNAME/../hooks/scripts"

# ─── pre-tool.sh ──────────────────────────────────────────────────────────────

@test "pre-tool: allows non-bash tool (view)" {
  local input='{"toolName":"view","toolArgs":"{\"path\":\"/tmp\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows safe bash command (git)" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"git status\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows uv run python" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"uv run python script.py\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows uv add package" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"uv add requests\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows uvx tool" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"uvx ruff check .\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: denies python at command start" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"python script.py\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies python3 at command start" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"python3 -m pip install requests\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies pip install" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pip install requests\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies pip3 install" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pip3 install numpy\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies virtualenv" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"virtualenv .venv\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies python after semicolon" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"echo hello; python script.py\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: deny response is valid JSON" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pip install flask\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  echo "$output" | jq . >/dev/null
}

@test "pre-tool: deny response contains reason" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"pip install flask\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  reason="$(echo "$output" | jq -r '.permissionDecisionReason')"
  [ -n "$reason" ]
}

# ─── pre-tool.sh: zuban / mypy enforcement ───────────────────────────────────

@test "pre-tool: denies direct mypy usage" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"mypy src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: denies python -m mypy" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"python -m mypy .\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  decision="$(echo "$output" | jq -r '.permissionDecision')"
  [ "$decision" = "deny" ]
}

@test "pre-tool: allows zmypy (zuban drop-in)" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"zmypy src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: allows uv run zmypy" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"uv run zmypy src/\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "pre-tool: mypy deny response contains zmypy guidance" {
  local input='{"toolName":"bash","toolArgs":"{\"command\":\"mypy .\"}"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/pre-tool.sh'"
  [ "$status" -eq 0 ]
  reason="$(echo "$output" | jq -r '.permissionDecisionReason')"
  [[ "$reason" == *"zmypy"* ]]
}

# ─── session-start.sh ─────────────────────────────────────────────────────────

@test "session-start: exits successfully" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [ "$status" -eq 0 ]
}

@test "session-start: outputs policy banner" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"POLICY"* ]]
}

@test "session-start: banner mentions uv" {
  local input='{"timestamp":1704614400000,"cwd":"/tmp","source":"new"}'
  run bash -c "echo '$input' | '$SCRIPTS_DIR/session-start.sh'"
  [[ "$output" == *"uv"* ]]
}
