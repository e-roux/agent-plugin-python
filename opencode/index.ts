/**
 * OpenCode plugin: Python toolchain enforcer.
 *
 * Mirrors the copilot-cli pre-tool hook: blocks direct python/pip/virtualenv/mypy/poetry
 * calls and directs the agent to use uv and zmypy instead.
 *
 * Install via npm (add to opencode.json config):
 *   { "plugin": ["opencode-python-enforcer"] }
 *
 * Install from this repository (project-level):
 *   Copy core.ts + index.ts to .opencode/plugins/
 */
import type { Plugin } from "@opencode-ai/plugin";
import { appendFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { BASH_TOOL_ADDENDUM, PYTHON_POLICY, defaultRules, intercept } from "./core";

export const PythonEnforcerPlugin: Plugin = async ({ directory }) => {
  const logDir = join(directory, ".opencode", "logs");
  const deniedLog = join(logDir, "pre-tool-denied.log");

  return {
    // ── Proactive policy injection ────────────────────────────────────────────

    // Inject Python toolchain policy into the system prompt so the LLM knows
    // the rules before it has a chance to violate them.
    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PYTHON_POLICY);
    },

    // Augment the bash tool description so the blocked-command list appears
    // in every tool-call context window.
    "tool.definition": async (input, output) => {
      if (input.toolID === "bash") {
        output.description += BASH_TOOL_ADDENDUM;
      }
    },

    // Preserve the Python toolchain policy during session compaction so it
    // survives long sessions that summarise their history.
    "experimental.session.compacting": async (_input, output) => {
      output.context.push(PYTHON_POLICY);
    },

    // ── Reactive enforcement ──────────────────────────────────────────────────

    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return;

      const command: unknown = (output as { args?: { command?: unknown } }).args
        ?.command;
      if (typeof command !== "string") return;

      const trimmed = command.trimStart();
      if (!trimmed) return;

      try {
        intercept(trimmed, defaultRules);
      } catch (err) {
        // Log denial for audit and test assertions.
        try {
          mkdirSync(logDir, { recursive: true });
          appendFileSync(
            deniedLog,
            `denied at ${new Date().toISOString()}: ${trimmed}\n`,
          );
        } catch {
          // Logging failure must never block the enforcement.
        }
        throw err;
      }
    },
  };
};
