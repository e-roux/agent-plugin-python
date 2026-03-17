/**
 * Command interceptor — pure logic.
 *
 * Enforces the same policy as the copilot pre-tool hook:
 *   python / pip / virtualenv / mypy must not be called directly.
 *   Use uv (package manager) and zmypy (zuban type checker) instead.
 *
 * No runtime dependencies. Tested with `bun test`.
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface BlockRule {
  match: RegExp;
  action: "block";
  message: string;
}

export interface RewriteRule {
  match: RegExp;
  action: "rewrite";
  rewrite: (command: string) => string;
}

export type InterceptRule = BlockRule | RewriteRule;

// ---------------------------------------------------------------------------
// Matching helpers
// ---------------------------------------------------------------------------

/**
 * Build a regex that matches `token` at the start of a command OR immediately
 * after a shell operator (; & |), with optional surrounding whitespace.
 * The token must be followed by whitespace or end-of-string (word boundary).
 *
 * Equivalent to the bash pattern:
 *   (^|[;&|][[:space:]]*)<token>([[:space:]]|$)
 */
function shellToken(token: string): RegExp {
  return new RegExp(`(?:^|[;&|]\\s*)${token}(?:\\s|$)`);
}

// ---------------------------------------------------------------------------
// Core functions (exported for unit testing)
// ---------------------------------------------------------------------------

/** Test whether a command matches a rule's pattern. */
export function matchesRule(command: string, rule: InterceptRule): boolean {
  return rule.match.test(command);
}

/** Find the first matching rule for a command (first-wins). */
export function findMatchingRule(
  command: string,
  rules: readonly InterceptRule[],
): InterceptRule | undefined {
  return rules.find((rule) => matchesRule(command, rule));
}

/**
 * Apply a matched rule to a command.
 * - block rules throw an Error with the configured message.
 * - rewrite rules return the transformed command (the rewrite fn may throw too).
 */
export function applyRule(command: string, rule: InterceptRule): string {
  if (rule.action === "block") {
    throw new Error(rule.message);
  }
  return rule.rewrite(command);
}

/**
 * Run a command through the full rule list.
 * Returns the (possibly rewritten) command, or throws if blocked.
 * When no rule matches the command is returned unchanged.
 */
export function intercept(
  command: string,
  rules: readonly InterceptRule[],
): string {
  const rule = findMatchingRule(command, rules);
  if (!rule) return command;
  return applyRule(command, rule);
}

// ---------------------------------------------------------------------------
// Policy text — reused in system-prompt injection and compaction context
// ---------------------------------------------------------------------------

/**
 * Python toolchain policy text injected into the LLM system prompt and
 * preserved during session compaction.  Ensures the model knows the rules
 * before it has a chance to violate them.
 */
export const PYTHON_POLICY = `\
## Python toolchain policy

Use **uv** for all Python dependency and environment management. Direct use of
python, pip, virtualenv, mypy, and poetry is FORBIDDEN.

### Forbidden commands — use uv / zmypy instead

| Forbidden command       | Use instead                                   |
|-------------------------|-----------------------------------------------|
| python / python3        | uv run script.py · uv run python              |
| python -m pip           | uv add <package>                              |
| pip / pip3              | uv add <package>                              |
| python -m venv          | uv venv                                       |
| virtualenv              | uv venv                                       |
| mypy / python -m mypy   | zmypy src/ · uv run zmypy src/                |
| poetry                  | uv init · uv add · uv sync · uv run           |

### Quick reference

\`\`\`bash
uv run script.py          # run a script (resolves inline deps)
uv run python             # start the interpreter
uv add <package>          # add a dependency (updates pyproject.toml)
uv sync                   # restore all dependencies
uv venv                   # create a virtual environment
zmypy src/                # type-check with zuban drop-in for mypy
uv run zmypy src/         # same, via uv
\`\`\``;

/**
 * Short addendum appended to the bash tool description so the LLM sees
 * the blocked-command list in every tool-call context window.
 */
export const BASH_TOOL_ADDENDUM = `\

⚠️  Python toolchain policy — the following commands are FORBIDDEN:
python · python3 · pip · pip3 · virtualenv · mypy · poetry
Use uv (uv run, uv add, uv sync, uv venv) and zmypy instead.`;

// ---------------------------------------------------------------------------
// Default rules — mirror the copilot pre-tool hook enforcement
// More-specific rules are listed first (first-wins matching).
// ---------------------------------------------------------------------------

export const defaultRules: readonly InterceptRule[] = [
  // ── python -m pip ──────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)python3?\s+-m\s+pip\b/,
    action: "block",
    message:
      "'python -m pip' is forbidden. Use uv instead:\n\n" +
      "  uv add <package>            — add dependency to project\n" +
      "  uv run --with <pkg> <cmd>   — one-shot with inline dep",
  },

  // ── python -m venv ─────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)python3?\s+-m\s+venv\b/,
    action: "block",
    message: "'python -m venv' is forbidden. Use 'uv venv' instead.",
  },

  // ── python -m mypy ─────────────────────────────────────────────────
  {
    match: /(?:^|[;&|]\s*)python3?\s+-m\s+mypy\b/,
    action: "block",
    message:
      "'python -m mypy' is forbidden. Use zmypy (zuban drop-in) instead:\n\n" +
      "  zmypy src/          — check a directory\n" +
      "  uv run zmypy src/   — via uv",
  },

  // ── pip / pip3 ─────────────────────────────────────────────────────
  {
    match: shellToken("pip3?"),
    action: "block",
    message:
      "pip is forbidden. Use uv instead:\n\n" +
      "  uv add <package>            — add dependency to project\n" +
      "  uv run --with <pkg> <cmd>   — one-shot with inline dep",
  },

  // ── virtualenv ─────────────────────────────────────────────────────
  {
    match: shellToken("virtualenv"),
    action: "block",
    message:
      "virtualenv is forbidden. Use 'uv venv' or let uv manage the venv automatically.",
  },

  // ── mypy (direct) ──────────────────────────────────────────────────
  // zmypy, uv run zmypy, uvx zmypy are all allowed (not matched by this pattern).
  {
    match: shellToken("mypy"),
    action: "block",
    message:
      "mypy is forbidden. Use zmypy (zuban drop-in replacement) instead:\n\n" +
      "  zmypy src/          — check a directory\n" +
      "  uv run zmypy src/   — via uv",
  },

  // ── poetry ─────────────────────────────────────────────────────────
  {
    match: shellToken("poetry"),
    action: "block",
    message:
      "poetry is forbidden. Use uv instead (uv init, uv add, uv sync, uv run).",
  },

  // ── python / python3 ───────────────────────────────────────────────
  // Comes last so more-specific python -m * rules take priority.
  {
    match: shellToken("python3?"),
    action: "block",
    message:
      "Direct python/python3 is forbidden. Use uv instead:\n\n" +
      "  uv run script.py       — run a script (with inline deps)\n" +
      "  uv run python          — start the interpreter\n" +
      "  uv add <package>       — add a dependency",
  },
];
