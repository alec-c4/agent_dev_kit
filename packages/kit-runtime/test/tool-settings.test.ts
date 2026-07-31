import { describe, expect, test } from "bun:test";
import {
  attributionToClaude,
  attributionToCursor,
  buildClaudePayload,
  buildCursorPayload,
  mergeListUnion,
  mergePermissions,
  mergeSection,
  resolveAttributionFlags,
} from "../src/tool-settings.ts";

describe("mergeListUnion", () => {
  test("unions lists and preserves first-seen order", () => {
    expect(mergeListUnion(["a", "b"], ["b", "c"], ["a", "d"])).toEqual([
      "a",
      "b",
      "c",
      "d",
    ]);
  });

  test("treats null/undefined lists as empty", () => {
    expect(mergeListUnion(null, undefined, ["x"])).toEqual(["x"]);
  });
});

describe("mergePermissions", () => {
  test("union-merges allow/deny/ask without dropping base entries", () => {
    const merged = mergePermissions(
      { allow: ["Shell(git)"], deny: ["Shell(rm)"] },
      { allow: ["Shell(gh)"], ask: ["Shell(sudo)"] },
      { deny: ["Shell(rm)", "Shell(dd)"] },
    );
    expect(merged.allow).toEqual(["Shell(git)", "Shell(gh)"]);
    expect(merged.deny).toEqual(["Shell(rm)", "Shell(dd)"]);
    expect(merged.ask).toEqual(["Shell(sudo)"]);
  });
});

describe("mergeSection", () => {
  test("merges permissions and overlays scalar keys", () => {
    const merged = mergeSection(
      { permissions: { allow: ["A"] }, approvalMode: "default" },
      [
        { permissions: { allow: ["B"] }, approvalMode: "unrestricted" },
        { maxMode: true },
      ],
      { scalarKeys: ["approvalMode", "maxMode"] },
    );
    expect(merged.permissions).toEqual({ allow: ["A", "B"] });
    expect(merged.approvalMode).toEqual("unrestricted");
    expect(merged.maxMode).toEqual(true);
  });
});

describe("attribution helpers", () => {
  test("attributionToCursor maps booleans to Cursor keys", () => {
    expect(attributionToCursor(false, true)).toEqual({
      attributeCommitsToAgent: false,
      attributePRsToAgent: true,
    });
  });

  test("attributionToClaude returns null when both enabled (leave defaults)", () => {
    expect(attributionToClaude(true, true)).toBeNull();
  });

  test("attributionToClaude uses empty strings to disable trailers", () => {
    expect(attributionToClaude(false, false)).toEqual({ commit: "", pr: "" });
    expect(attributionToClaude(false, true)).toEqual({ commit: "" });
    expect(attributionToClaude(true, false)).toEqual({ pr: "" });
  });
});

describe("resolveAttributionFlags", () => {
  test("disable/enable CLI flags win", () => {
    expect(
      resolveAttributionFlags(
        { attribution: { commits: true, prs: true } },
        { commits: null, prs: null, disable: true, enable: false },
      ),
    ).toEqual([false, false]);
    expect(
      resolveAttributionFlags(
        { attribution: { commits: false, prs: false } },
        { commits: null, prs: null, disable: false, enable: true },
      ),
    ).toEqual([true, true]);
  });

  test("falls back to attribution.enabled when commits/prs absent", () => {
    expect(
      resolveAttributionFlags(
        { attribution: { enabled: false } },
        { commits: null, prs: null, disable: false, enable: false },
      ),
    ).toEqual([false, false]);
  });

  test("defaults missing sides to true", () => {
    expect(
      resolveAttributionFlags(
        { attribution: { commits: false } },
        { commits: null, prs: null, disable: false, enable: false },
      ),
    ).toEqual([false, true]);
  });
});

describe("build payloads", () => {
  test("buildCursorPayload sets version and attribution", () => {
    const payload = buildCursorPayload(
      { permissions: { allow: ["Shell(local)"] } },
      { permissions: { allow: ["Shell(gh)"] }, approvalMode: "unrestricted" },
      { permissions: { allow: ["Mcp(x)"] } },
      { commits: false, prs: false },
    );
    expect(payload.version).toBe(1);
    expect(payload.permissions).toEqual({
      allow: ["Shell(local)", "Shell(gh)", "Mcp(x)"],
    });
    expect(payload.approvalMode).toBe("unrestricted");
    expect(payload.attribution).toEqual({
      attributeCommitsToAgent: false,
      attributePRsToAgent: false,
    });
  });

  test("buildClaudePayload drops includeCoAuthoredBy and sets empty attribution", () => {
    const payload = buildClaudePayload(
      { includeCoAuthoredBy: true, permissions: { allow: ["Bash(git *)"] } },
      { permissions: { allow: ["Bash(gh *)"] }, includeGitInstructions: true },
      {},
      { commits: false, prs: false },
    );
    expect(payload.includeCoAuthoredBy).toBeUndefined();
    expect(payload.includeGitInstructions).toBe(true);
    expect(payload.permissions).toEqual({
      allow: ["Bash(git *)", "Bash(gh *)"],
    });
    expect(payload.attribution).toEqual({ commit: "", pr: "" });
  });

  test("buildClaudePayload removes attribution when both enabled", () => {
    const payload = buildClaudePayload(
      { attribution: { commit: "", pr: "" } },
      {},
      {},
      { commits: true, prs: true },
    );
    expect(payload.attribution).toBeUndefined();
  });
});
