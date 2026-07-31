/**
 * Merge kit tool settings into Cursor cli-config and Claude Code settings.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export const PERMISSION_LIST_KEYS = ["allow", "deny", "ask"] as const;
export const CURSOR_SCALAR_KEYS = ["approvalMode", "maxMode"] as const;
export const CLAUDE_SCALAR_KEYS = ["includeGitInstructions", "defaultMode"] as const;

export type JsonObject = Record<string, unknown>;

export function loadJson(path: string): JsonObject {
  if (!existsSync(path)) return {};
  const text = readFileSync(path, "utf8").trim();
  if (!text) return {};
  const data = JSON.parse(text) as unknown;
  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw new Error(`Invalid JSON object in ${path}`);
  }
  return data as JsonObject;
}

export function writeJson(
  path: string,
  payload: JsonObject,
  opts: { dryRun: boolean },
): void {
  const rendered = JSON.stringify(payload, null, 2) + "\n";
  if (opts.dryRun) {
    process.stdout.write(rendered);
    return;
  }
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, rendered, "utf8");
}

export function mergeListUnion(...lists: (unknown[] | null | undefined)[]): unknown[] {
  const seen = new Set<unknown>();
  const merged: unknown[] = [];
  for (const lst of lists) {
    for (const item of lst ?? []) {
      if (seen.has(item)) continue;
      seen.add(item);
      merged.push(item);
    }
  }
  return merged;
}

export function mergePermissions(
  base: JsonObject | null | undefined,
  ...overlays: (JsonObject | null | undefined)[]
): JsonObject {
  const result: JsonObject = { ...(base ?? {}) };
  for (const overlay of overlays) {
    if (!overlay) continue;
    for (const key of PERMISSION_LIST_KEYS) {
      if (!(key in overlay)) continue;
      result[key] = mergeListUnion(
        result[key] as unknown[] | undefined,
        overlay[key] as unknown[] | undefined,
      );
    }
  }
  return result;
}

export function mergeSection(
  base: JsonObject,
  overlays: (JsonObject | null | undefined)[],
  opts: { scalarKeys?: readonly string[] } = {},
): JsonObject {
  const scalarKeys = opts.scalarKeys ?? [];
  const result = structuredClone(base) as JsonObject;
  for (const overlay of overlays) {
    if (!overlay) continue;
    if ("permissions" in overlay) {
      result.permissions = mergePermissions(
        result.permissions as JsonObject | undefined,
        overlay.permissions as JsonObject | undefined,
      );
    }
    for (const key of scalarKeys) {
      if (key in overlay) {
        result[key] = overlay[key];
      }
    }
  }
  return result;
}

export function attributionToCursor(
  commits: boolean,
  prs: boolean,
): { attributeCommitsToAgent: boolean; attributePRsToAgent: boolean } {
  return {
    attributeCommitsToAgent: commits,
    attributePRsToAgent: prs,
  };
}

/**
 * Claude Code's `attribution.commit`/`attribution.pr` hold the trailer
 * text to add; empty string disables it. `includeCoAuthoredBy` is the
 * deprecated boolean predecessor — superseded by `attribution`.
 */
export function attributionToClaude(
  commits: boolean,
  prs: boolean,
): Record<string, string> | null {
  if (commits && prs) return null;
  const payload: Record<string, string> = {};
  if (!commits) payload.commit = "";
  if (!prs) payload.pr = "";
  return payload;
}

export function resolveAttributionFlags(
  section: JsonObject,
  opts: {
    commits: boolean | null;
    prs: boolean | null;
    disable: boolean;
    enable: boolean;
  },
): [boolean, boolean] {
  if (opts.disable) return [false, false];
  if (opts.enable) return [true, true];

  const attr = (section.attribution as JsonObject | undefined) ?? {};
  const resolvedCommits =
    opts.commits !== null ? opts.commits : attr.commits;
  const resolvedPrs = opts.prs !== null ? opts.prs : attr.prs;

  if (typeof resolvedCommits === "boolean" && typeof resolvedPrs === "boolean") {
    return [resolvedCommits, resolvedPrs];
  }
  if (
    resolvedCommits === undefined &&
    resolvedPrs === undefined &&
    "enabled" in attr
  ) {
    const enabled = Boolean(attr.enabled);
    return [enabled, enabled];
  }
  return [
    typeof resolvedCommits === "boolean" ? resolvedCommits : true,
    typeof resolvedPrs === "boolean" ? resolvedPrs : true,
  ];
}

export function buildCursorPayload(
  existing: JsonObject,
  kitDefaults: JsonObject,
  userSection: JsonObject,
  opts: { commits: boolean; prs: boolean },
): JsonObject {
  const payload = structuredClone(existing) as JsonObject;
  if (!("version" in payload)) {
    payload.version = 1;
  }

  const merged = mergeSection({}, [kitDefaults, userSection], {
    scalarKeys: CURSOR_SCALAR_KEYS,
  });
  if (merged.permissions) {
    payload.permissions = mergePermissions(
      payload.permissions as JsonObject | undefined,
      merged.permissions as JsonObject,
    );
  }
  for (const key of CURSOR_SCALAR_KEYS) {
    if (key in merged) payload[key] = merged[key];
  }

  payload.attribution = attributionToCursor(opts.commits, opts.prs);
  return payload;
}

export function buildClaudePayload(
  existing: JsonObject,
  kitDefaults: JsonObject,
  userSection: JsonObject,
  opts: { commits: boolean; prs: boolean },
): JsonObject {
  const payload = structuredClone(existing) as JsonObject;
  delete payload.includeCoAuthoredBy; // deprecated in favor of `attribution`

  const merged = mergeSection({}, [kitDefaults, userSection], {
    scalarKeys: CLAUDE_SCALAR_KEYS,
  });
  if (merged.permissions) {
    payload.permissions = mergePermissions(
      payload.permissions as JsonObject | undefined,
      merged.permissions as JsonObject,
    );
  }
  for (const key of CLAUDE_SCALAR_KEYS) {
    if (key in merged) payload[key] = merged[key];
  }

  const claudeAttr = attributionToClaude(opts.commits, opts.prs);
  if (claudeAttr === null) {
    delete payload.attribution;
  } else {
    payload.attribution = claudeAttr;
  }
  return payload;
}

export function applyCursorSettings(
  cliPath: string,
  kitDefaults: JsonObject,
  userSection: JsonObject,
  opts: { commits: boolean; prs: boolean; dryRun: boolean },
): JsonObject {
  const existing = loadJson(cliPath);
  const payload = buildCursorPayload(existing, kitDefaults, userSection, {
    commits: opts.commits,
    prs: opts.prs,
  });
  writeJson(cliPath, payload, { dryRun: opts.dryRun });
  return payload;
}

export function applyClaudeSettings(
  settingsPath: string,
  kitDefaults: JsonObject,
  userSection: JsonObject,
  opts: { commits: boolean; prs: boolean; dryRun: boolean },
): JsonObject {
  const existing = loadJson(settingsPath);
  const payload = buildClaudePayload(existing, kitDefaults, userSection, {
    commits: opts.commits,
    prs: opts.prs,
  });
  writeJson(settingsPath, payload, { dryRun: opts.dryRun });
  return payload;
}
