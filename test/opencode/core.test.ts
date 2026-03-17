/**
 * Unit tests for opencode/core.ts — pure rule logic.
 * Run with: bun test test/opencode.test.ts
 */
import { describe, it, expect } from "bun:test";
import {
  matchesRule,
  findMatchingRule,
  applyRule,
  intercept,
  defaultRules,
  PYTHON_POLICY,
  BASH_TOOL_ADDENDUM,
  type BlockRule,
  type RewriteRule,
} from "../../opencode/core";

// ── matchesRule ──────────────────────────────────────────────────────────────

describe("matchesRule", () => {
  const block: BlockRule = { match: /^pip\b/, action: "block", message: "no" };

  it("matches when regex test passes", () => {
    expect(matchesRule("pip install requests", block)).toBe(true);
  });

  it("does not match when regex test fails", () => {
    expect(matchesRule("uv add requests", block)).toBe(false);
  });
});

// ── findMatchingRule ─────────────────────────────────────────────────────────

describe("findMatchingRule", () => {
  it("returns first matching rule", () => {
    const r1: BlockRule = { match: /^pip/, action: "block", message: "pip" };
    const r2: BlockRule = { match: /^uv/, action: "block", message: "uv" };
    expect(findMatchingRule("pip install x", [r1, r2])).toBe(r1);
  });

  it("returns undefined when no rule matches", () => {
    const r1: BlockRule = { match: /^pip/, action: "block", message: "pip" };
    expect(findMatchingRule("git status", [r1])).toBeUndefined();
  });
});

// ── applyRule ────────────────────────────────────────────────────────────────

describe("applyRule", () => {
  it("block rule throws with message", () => {
    const rule: BlockRule = { match: /x/, action: "block", message: "blocked!" };
    expect(() => applyRule("x", rule)).toThrow("blocked!");
  });

  it("rewrite rule returns transformed command", () => {
    const rule: RewriteRule = {
      match: /x/,
      action: "rewrite",
      rewrite: () => "rewritten",
    };
    expect(applyRule("x", rule)).toBe("rewritten");
  });
});

// ── intercept ────────────────────────────────────────────────────────────────

describe("intercept", () => {
  it("returns command unchanged when no rule matches", () => {
    expect(intercept("git status", defaultRules)).toBe("git status");
  });

  it("throws when a block rule matches", () => {
    expect(() => intercept("pip install requests", defaultRules)).toThrow();
  });
});

// ── defaultRules: pip ────────────────────────────────────────────────────────

describe("defaultRules — pip", () => {
  it("blocks pip at command start", () => {
    expect(() => intercept("pip install requests", defaultRules)).toThrow();
  });

  it("blocks pip3 at command start", () => {
    expect(() => intercept("pip3 install numpy", defaultRules)).toThrow();
  });

  it("blocks pip after semicolon", () => {
    expect(() => intercept("echo hi; pip install x", defaultRules)).toThrow();
  });

  it("blocks pip after &&", () => {
    expect(() => intercept("echo hi && pip install x", defaultRules)).toThrow();
  });

  it("blocks pip after pipe", () => {
    expect(() => intercept("cat req.txt | pip install -r -", defaultRules)).toThrow();
  });

  it("deny message mentions uv", () => {
    try {
      intercept("pip install requests", defaultRules);
    } catch (err) {
      expect((err as Error).message).toContain("uv");
    }
  });

  it("does not block uv add (no pip)", () => {
    expect(intercept("uv add requests", defaultRules)).toBe("uv add requests");
  });
});

// ── defaultRules: virtualenv ─────────────────────────────────────────────────

describe("defaultRules — virtualenv", () => {
  it("blocks virtualenv at command start", () => {
    expect(() => intercept("virtualenv .venv", defaultRules)).toThrow();
  });

  it("blocks virtualenv after &&", () => {
    expect(() => intercept("cd /tmp && virtualenv .venv", defaultRules)).toThrow();
  });

  it("deny message mentions uv", () => {
    try {
      intercept("virtualenv .venv", defaultRules);
    } catch (err) {
      expect((err as Error).message).toContain("uv");
    }
  });
});

// ── defaultRules: mypy ───────────────────────────────────────────────────────

describe("defaultRules — mypy", () => {
  it("blocks mypy at command start", () => {
    expect(() => intercept("mypy .", defaultRules)).toThrow();
  });

  it("blocks mypy after &&", () => {
    expect(() => intercept("echo check && mypy src/", defaultRules)).toThrow();
  });

  it("deny message mentions zmypy", () => {
    try {
      intercept("mypy .", defaultRules);
    } catch (err) {
      expect((err as Error).message).toContain("zmypy");
    }
  });

  it("does not block zmypy", () => {
    expect(intercept("zmypy src/", defaultRules)).toBe("zmypy src/");
  });

  it("does not block uv run zmypy", () => {
    expect(intercept("uv run zmypy src/", defaultRules)).toBe("uv run zmypy src/");
  });
});

// ── defaultRules: poetry ─────────────────────────────────────────────────────

describe("defaultRules — poetry", () => {
  it("blocks poetry at command start", () => {
    expect(() => intercept("poetry install", defaultRules)).toThrow();
  });

  it("deny message mentions uv", () => {
    try {
      intercept("poetry install", defaultRules);
    } catch (err) {
      expect((err as Error).message).toContain("uv");
    }
  });
});

// ── defaultRules: python ─────────────────────────────────────────────────────

describe("defaultRules — python", () => {
  it("blocks bare python", () => {
    expect(() => intercept("python script.py", defaultRules)).toThrow();
  });

  it("blocks python3", () => {
    expect(() => intercept("python3 script.py", defaultRules)).toThrow();
  });

  it("blocks python after semicolon", () => {
    expect(() => intercept("echo hi; python script.py", defaultRules)).toThrow();
  });

  it("blocks python -m pip", () => {
    expect(() => intercept("python -m pip install x", defaultRules)).toThrow();
  });

  it("blocks python -m venv", () => {
    expect(() => intercept("python -m venv .venv", defaultRules)).toThrow();
  });

  it("blocks python -m mypy with zmypy guidance", () => {
    try {
      intercept("python -m mypy .", defaultRules);
    } catch (err) {
      expect((err as Error).message).toContain("zmypy");
    }
  });

  it("does not block uv run python", () => {
    expect(intercept("uv run python script.py", defaultRules)).toBe(
      "uv run python script.py",
    );
  });

  it("does not block uvx ruff check", () => {
    expect(intercept("uvx ruff check .", defaultRules)).toBe("uvx ruff check .");
  });

  it("does not block git commands", () => {
    expect(intercept("git status", defaultRules)).toBe("git status");
  });

  it("does not block uv add", () => {
    expect(intercept("uv add requests", defaultRules)).toBe("uv add requests");
  });
});

// ── PYTHON_POLICY ────────────────────────────────────────────────────────────

describe("PYTHON_POLICY", () => {
  it("is a non-empty string", () => {
    expect(typeof PYTHON_POLICY).toBe("string");
    expect(PYTHON_POLICY.length).toBeGreaterThan(0);
  });

  it("mentions all forbidden commands", () => {
    const forbidden = ["python", "pip", "virtualenv", "mypy", "poetry"];
    for (const cmd of forbidden) {
      expect(PYTHON_POLICY).toContain(cmd);
    }
  });

  it("mentions uv as the replacement", () => {
    expect(PYTHON_POLICY).toContain("uv");
  });

  it("mentions zmypy as the mypy replacement", () => {
    expect(PYTHON_POLICY).toContain("zmypy");
  });
});

// ── BASH_TOOL_ADDENDUM ───────────────────────────────────────────────────────

describe("BASH_TOOL_ADDENDUM", () => {
  it("is a non-empty string", () => {
    expect(typeof BASH_TOOL_ADDENDUM).toBe("string");
    expect(BASH_TOOL_ADDENDUM.length).toBeGreaterThan(0);
  });

  it("mentions forbidden commands", () => {
    expect(BASH_TOOL_ADDENDUM).toContain("python");
    expect(BASH_TOOL_ADDENDUM).toContain("pip");
    expect(BASH_TOOL_ADDENDUM).toContain("mypy");
    expect(BASH_TOOL_ADDENDUM).toContain("poetry");
  });

  it("suggests uv as the alternative", () => {
    expect(BASH_TOOL_ADDENDUM).toContain("uv");
  });
});
