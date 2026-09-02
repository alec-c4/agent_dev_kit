import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { appendFinding, regressFingerprint } from "./findings.ts";

export type PatternDef = {
  fingerprint: string;
  stack: string;
  guide: string;
  tokens?: string[];
  sensor?: string;
};

export type PatternHit = {
  fingerprint: string;
  path: string;
  token: string;
  guide: string;
};

export type CheckPatternsResult = {
  ok: boolean;
  skipped: boolean;
  hits: PatternHit[];
};

const SKIP_DIR = new Set([
  ".git",
  ".ai",
  "node_modules",
  "vendor",
  "dist",
  "coverage",
  ".bun",
]);

const SKIP_PATH_PREFIX = ["docs/examples/", "docs/guidelines/", "skills/"];
const SKIP_FILES = new Set(["AGENTS.md", "CLAUDE.md", "GEMINI.md"]);

export function loadPatternCatalog(path: string): PatternDef[] {
  if (!existsSync(path)) return [];
  return parseCatalog(readFileSync(path, "utf8"));
}

type CatalogFile = {
  patterns?: PatternDef[];
  sensor_patterns?: PatternDef[];
};

function readCatalog(text: string): CatalogFile {
  return (Bun.YAML.parse(text) as CatalogFile | null) ?? {};
}

function defs(list: unknown): PatternDef[] {
  return (Array.isArray(list) ? list : []).filter(
    (p): p is PatternDef =>
      !!p && typeof (p as PatternDef).fingerprint === "string",
  );
}

/** Token-scanned fingerprints — the ones `checkPatterns` can raise itself. */
export function parseCatalog(text: string): PatternDef[] {
  return defs(readCatalog(text).patterns);
}

/**
 * Fingerprints owned by a named sensor rather than a token scan. They can
 * never be raised by `checkPatterns`, so the verifier has to assert them; the
 * catalog keeps the wording in one place.
 */
export function parseSensorCatalog(text: string): PatternDef[] {
  return defs(readCatalog(text).sensor_patterns);
}

export function loadSensorCatalog(path: string): PatternDef[] {
  if (!existsSync(path)) return [];
  return parseSensorCatalog(readFileSync(path, "utf8"));
}

function shouldSkipFile(root: string, abs: string): boolean {
  const rel = relative(root, abs).split("\\").join("/");
  if (SKIP_FILES.has(rel.split("/").pop() || "")) return true;
  for (const prefix of SKIP_PATH_PREFIX) {
    if (rel.startsWith(prefix)) return true;
  }
  return false;
}

function walkFiles(root: string, dir: string, out: string[]): void {
  let entries: string[] = [];
  try {
    entries = readdirSync(dir);
  } catch {
    return;
  }
  for (const name of entries) {
    if (SKIP_DIR.has(name)) continue;
    const abs = join(dir, name);
    let st;
    try {
      st = statSync(abs);
    } catch {
      continue;
    }
    if (st.isDirectory()) walkFiles(root, abs, out);
    else if (st.isFile() && st.size <= 1_000_000) out.push(abs);
  }
}

export function checkPatterns(
  projectRoot: string,
  opts: {
    catalogText?: string;
    catalogPath?: string;
    enabled?: boolean;
    workRef?: string;
  } = {},
): CheckPatternsResult {
  if (opts.enabled === false) {
    return { ok: true, skipped: true, hits: [] };
  }
  const catalog = opts.catalogText
    ? parseCatalog(opts.catalogText)
    : opts.catalogPath
      ? loadPatternCatalog(opts.catalogPath)
      : [];
  if (!catalog.length) return { ok: true, skipped: false, hits: [] };

  const files: string[] = [];
  walkFiles(projectRoot, projectRoot, files);
  const hits: PatternHit[] = [];
  for (const file of files) {
    if (shouldSkipFile(projectRoot, file)) continue;
    let text = "";
    try {
      text = readFileSync(file, "utf8");
    } catch {
      continue;
    }
    if (text.includes("\u0000")) continue;
    const rel = relative(projectRoot, file).split("\\").join("/");
    for (const pat of catalog) {
      for (const token of pat.tokens ?? []) {
        if (token && text.includes(token)) {
          hits.push({
            fingerprint: pat.fingerprint,
            path: rel,
            token,
            guide: pat.guide,
          });
        }
      }
    }
  }

  if (opts.workRef && hits.length) {
    const byFp = new Map<string, PatternHit[]>();
    for (const h of hits) {
      const list = byFp.get(h.fingerprint) ?? [];
      list.push(h);
      byFp.set(h.fingerprint, list);
    }
    for (const [fp, list] of byFp) {
      const evidence = list
        .slice(0, 5)
        .map((h) => `${h.path} (${h.token})`)
        .join("; ");
      const guide = list[0].guide;
      regressFingerprint(projectRoot, opts.workRef, fp);
      appendFinding(projectRoot, opts.workRef, {
        fingerprint: fp,
        stage: "verify",
        severity: "block",
        summary: guide,
        evidence,
      });
    }
  }

  return { ok: hits.length === 0, skipped: false, hits };
}
