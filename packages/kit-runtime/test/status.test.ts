import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { scanProject, formatStatusTable } from "../src/status.ts";

describe("status scanner", () => {
  test("infers intake from analysis only", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-status-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    writeFileSync(
      join(root, ".ai", "work", "GH-1-analysis.md"),
      "**Work ref:** GH-1\n**Spec key:** demo\n",
    );
    const rows = scanProject(root, "demo");
    expect(rows).toHaveLength(1);
    expect(rows[0].stage).toBe("intake");
    expect(rows[0].work_ref).toBe("GH-1");
    expect(rows[0].open_findings).toBe(0);
  });

  test("AC-13: open_findings counts open rows", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-status-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    writeFileSync(
      join(root, ".ai", "work", "GH-1-analysis.md"),
      "**Work ref:** GH-1\n",
    );
    writeFileSync(
      join(root, ".ai", "work", "GH-1-findings.md"),
      `# Findings: GH-1

| id | fingerprint | stage | severity | status | summary | evidence | opened | closed |
|----|-------------|-------|----------|--------|---------|----------|--------|--------|
| F-1 | a | verify | block | open | one | e | 2026-08-23 | |
| F-2 | b | review | block | open | two | e | 2026-08-23 | |
`,
    );
    const rows = scanProject(root, "demo");
    expect(rows[0].open_findings).toBe(2);
    expect(formatStatusTable(rows)).toContain("OPEN_FINDINGS");
    expect(formatStatusTable(rows)).toContain("\t2\t");
  });

  test("a spec without a work ref is not bound to an unrelated work item", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-status-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    mkdirSync(join(root, ".ai", "specs"), { recursive: true });
    writeFileSync(join(root, ".ai", "work", "GH-77-analysis.md"), "# Analysis\n");
    writeFileSync(
      join(root, ".ai", "specs", "other-feature-spec.md"),
      "# Spec: unrelated\n\n**Status:** approved\n**Spec key:** other-feature\n",
    );
    const rows = scanProject(root, "demo");
    expect(rows).toHaveLength(1);
    expect(rows[0].spec_key).toBeNull();
    expect(rows[0].stage).toBe("intake");
  });

  test("a spec is bound by its own work ref header", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-status-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    mkdirSync(join(root, ".ai", "specs"), { recursive: true });
    writeFileSync(join(root, ".ai", "work", "GH-77-analysis.md"), "# Analysis\n");
    writeFileSync(
      join(root, ".ai", "specs", "csv-export-spec.md"),
      "# Spec: csv\n\n**Status:** approved\n**Work ref:** GH-77\n",
    );
    const rows = scanProject(root, "demo");
    expect(rows[0].spec_key).toBe("csv-export");
    expect(rows[0].stage).toBe("plan");
  });
});
