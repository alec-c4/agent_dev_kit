import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  checkPatterns,
  loadPatternCatalog,
  parseSensorCatalog,
} from "../src/patterns.ts";
import { parseFindingsFile, findingsPath } from "../src/findings.ts";

const catalog = `
patterns:
  - fingerprint: shipped-process-language
    stack: "*"
    guide: Do not put process jargon in shipped paths
    tokens:
      - work_ref
      - spec_key
`;

describe("check-patterns (AC-12, AC-16)", () => {
  test("AC-16: empty catalog is a no-op success", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    const result = checkPatterns(root, { catalogText: "patterns: []" });
    expect(result.skipped).toBe(false);
    expect(result.hits).toEqual([]);
    expect(result.ok).toBe(true);
  });

  test("AC-12: shipped README hit; .ai/ miss", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    writeFileSync(join(root, "README.md"), "Set the work_ref in chat.\n");
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    writeFileSync(join(root, ".ai", "work", "x-plan.md"), "work_ref: GH-1\n");
    const result = checkPatterns(root, { catalogText: catalog });
    expect(result.ok).toBe(false);
    expect(result.hits.some((h) => h.path.endsWith("README.md"))).toBe(true);
    expect(result.hits.some((h) => h.path.includes(".ai/"))).toBe(false);
  });

  test("opt-out does not FAIL", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    writeFileSync(join(root, "README.md"), "work_ref here\n");
    const result = checkPatterns(root, {
      catalogText: catalog,
      enabled: false,
    });
    expect(result.skipped).toBe(true);
    expect(result.ok).toBe(true);
  });

  test("append finding when work_ref set", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    writeFileSync(join(root, "README.md"), "spec_key must not leak\n");
    const result = checkPatterns(root, {
      catalogText: catalog,
      workRef: "GH-1",
    });
    expect(result.ok).toBe(false);
    const rows = parseFindingsFile(findingsPath(root, "GH-1"));
    expect(rows[0].fingerprint).toBe("shipped-process-language");
    expect(rows[0].status).toBe("open");
  });

  test("loadPatternCatalog parses yaml", () => {
    const dir = mkdtempSync(join(tmpdir(), "kit-cat-"));
    const p = join(dir, "failure-patterns.yaml");
    writeFileSync(p, catalog);
    const loaded = loadPatternCatalog(p);
    expect(loaded[0].fingerprint).toBe("shipped-process-language");
  });
});

describe("sensor-owned fingerprints (AC-17)", () => {
  const withSensors = `
patterns:
  - fingerprint: has-tokens
    stack: "*"
    guide: token guide
    tokens: [needle]
sensor_patterns:
  - fingerprint: skipped-fresh-verifier
    stack: "*"
    guide: Run verification in a new agent session.
    sensor: verification
`;

  test("a sensor-only fingerprint is not token-scanned", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    writeFileSync(join(root, "README.md"), "skipped-fresh-verifier\n");
    const result = checkPatterns(root, { catalogText: withSensors });
    expect(result.hits).toEqual([]);
    expect(result.ok).toBe(true);
  });

  test("sensor fingerprints are readable so the verifier can assert them", () => {
    const rows = parseSensorCatalog(withSensors);
    expect(rows.map((r) => r.fingerprint)).toEqual(["skipped-fresh-verifier"]);
    expect(rows[0].sensor).toBe("verification");
  });

  test("the shipped catalog keeps sensor rows out of the token list", () => {
    const kitCatalog = loadPatternCatalog(
      join(import.meta.dir, "..", "..", "..", "registry", "failure-patterns.yaml"),
    );
    expect(kitCatalog.every((p) => (p.tokens ?? []).length > 0)).toBe(true);
  });
});

describe("kit-owned paths are not project source", () => {
  // A project that ran `kit deploy-skills --scope=project` has the kit's own
  // skills on disk. Those legitimately spell out work_ref and spec_key, so
  // scanning them raised a blocking finding on every run.
  test("deployed skills and adapter dirs are skipped", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    for (const rel of [
      [".agents", "skills", "feature"],
      [".claude", "skills", "feature"],
      [".cursor", "rules"],
      [".codex", "prompts"],
      [".gemini", "antigravity-cli"],
    ]) {
      mkdirSync(join(root, ...rel), { recursive: true });
      writeFileSync(join(root, ...rel, "SKILL.md"), "Record the work_ref.\n");
    }
    const result = checkPatterns(root, { catalogText: catalog });
    expect(result.hits).toEqual([]);
    expect(result.ok).toBe(true);
  });

  test("a project file next to them still hits", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-pat-"));
    mkdirSync(join(root, ".claude", "skills"), { recursive: true });
    writeFileSync(join(root, ".claude", "skills", "s.md"), "work_ref\n");
    writeFileSync(join(root, "README.md"), "work_ref\n");
    const result = checkPatterns(root, { catalogText: catalog });
    expect(result.hits.map((h) => h.path)).toEqual(["README.md"]);
  });
});
