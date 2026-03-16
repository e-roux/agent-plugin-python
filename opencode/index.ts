/**
 * OpenCode plugin: Python toolchain enforcer.
 *
 * Mirrors the copilot pre-tool hook: blocks direct python/pip/virtualenv/mypy
 * calls and directs the agent to use uv and zmypy instead.
 *
 * Install (global): copy core.ts + index.ts to ~/.config/opencode/plugins/
 * Install (project): copy core.ts + index.ts to .opencode/plugins/
 */
import type { Plugin } from "@opencode-ai/plugin";
import { appendFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { defaultRules, intercept } from "./core";

export const PythonEnforcerPlugin: Plugin = async ({ directory }) => {
  const logDir = join(directory, ".opencode", "logs");
  const deniedLog = join(logDir, "pre-tool-denied.log");

  return {
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
