import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  appendFinding,
  closeFinding,
  countOpenFindings,
  findingsGate,
  findingsPath,
  parseFindingsFile,
  regressFingerprint,
  serializeFindings,
  wontfixFinding,
  type Finding,
} from "../src/findings.ts";

function sampleRow(over: Partial<Finding> = {}): Finding {
  return {
    id: "F-1",
    fingerprint: "shipped-process-language",
    stage: "verify",
    severity: "block",
    status: "open",
    summary: "README mentions a process id",
    evidence: "README.md:12",
    opened: "2026-08-23",
    closed: "",
    ...over,
  };
}

describe("findings ledger (AC-1, AC-5, AC-16)", () => {
  test("AC-16: missing file parses as empty list", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    expect(parseFindingsFile(findingsPath(root, "GH-1"))).toEqual([]);
    expect(countOpenFindings(root, "GH-1")).toBe(0);
  });

  test("AC-1: append creates file with F-1 and required columns", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    const row = appendFinding(root, "GH-1", {
      fingerprint: "shipped-process-language",
      stage: "verify",
      severity: "block",
      summary: "README mentions a process id",
      evidence: "README.md:12",
    });
    expect(row.id).toBe("F-1");
    expect(row.status).toBe("open");
    expect(existsSync(findingsPath(root, "GH-1"))).toBe(true);
    const parsed = parseFindingsFile(findingsPath(root, "GH-1"));
    expect(parsed).toHaveLength(1);
    expect(parsed[0].fingerprint).toBe("shipped-process-language");
    expect(parsed[0].evidence).toBe("README.md:12");
  });

  test("duplicate open fingerprint updates evidence, does not add F-2", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    appendFinding(root, "GH-1", {
      fingerprint: "shipped-process-language",
      stage: "verify",
      severity: "block",
      summary: "first",
      evidence: "README.md:12",
    });
    const second = appendFinding(root, "GH-1", {
      fingerprint: "shipped-process-language",
      stage: "verify",
      severity: "block",
      summary: "first",
      evidence: "README.md:40",
    });
    expect(second.id).toBe("F-1");
    expect(parseFindingsFile(findingsPath(root, "GH-1"))).toHaveLength(1);
    expect(second.evidence).toBe("README.md:40");
  });

  test("AC-5: close without fromSensor throws", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    appendFinding(root, "GH-1", {
      fingerprint: "x",
      stage: "verify",
      severity: "block",
      summary: "s",
      evidence: "e",
    });
    expect(() => closeFinding(root, "GH-1", "F-1", { fromSensor: false })).toThrow(
      /from-sensor/,
    );
    expect(parseFindingsFile(findingsPath(root, "GH-1"))[0].status).toBe("open");
  });

  test("close with fromSensor sets closed", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    appendFinding(root, "GH-1", {
      fingerprint: "x",
      stage: "verify",
      severity: "block",
      summary: "s",
      evidence: "e",
    });
    closeFinding(root, "GH-1", "F-1", { fromSensor: true });
    const row = parseFindingsFile(findingsPath(root, "GH-1"))[0];
    expect(row.status).toBe("closed");
    expect(row.closed.length).toBeGreaterThan(0);
  });

  test("wontfix requires human flag", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    appendFinding(root, "GH-1", {
      fingerprint: "x",
      stage: "verify",
      severity: "block",
      summary: "s",
      evidence: "e",
    });
    expect(() => wontfixFinding(root, "GH-1", "F-1", { human: false })).toThrow(
      /human/,
    );
    wontfixFinding(root, "GH-1", "F-1", { human: true });
    expect(parseFindingsFile(findingsPath(root, "GH-1"))[0].status).toBe("wontfix");
  });

  test("AC-4: regressFingerprint marks closed row regressed", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    mkdirSync(join(root, ".ai", "work"), { recursive: true });
    appendFinding(root, "GH-1", {
      fingerprint: "shipped-process-language",
      stage: "verify",
      severity: "block",
      summary: "s",
      evidence: "e",
    });
    closeFinding(root, "GH-1", "F-1", { fromSensor: true });
    const hit = regressFingerprint(root, "GH-1", "shipped-process-language");
    expect(hit).toBe(true);
    expect(parseFindingsFile(findingsPath(root, "GH-1"))[0].status).toBe(
      "regressed",
    );
  });

  test("a pipe in summary or evidence does not shift columns", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-find-"));
    appendFinding(root, "GH-1", {
      fingerprint: "fp-pipe",
      stage: "verify",
      severity: "block",
      summary: "use A | not B",
      evidence: "src/x.ts | src/y.ts",
    });
    const rows = parseFindingsFile(findingsPath(root, "GH-1"));
    expect(rows).toHaveLength(1);
    expect(rows[0].summary).toBe("use A | not B");
    expect(rows[0].evidence).toBe("src/x.ts | src/y.ts");
    expect(rows[0].opened).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(rows[0].closed).toBe("");
    expect(countOpenFindings(root, "GH-1")).toBe(1);
  });

  test("round-trip serialize keeps columns", () => {
    const rows: Finding[] = [sampleRow({ id: "F-2", severity: "warn" })];
    const md = serializeFindings("GH-1", rows);
    expect(md).toContain("| id | fingerprint |");
    const p = join(mkdtempSync(join(tmpdir(), "kit-rt-")), "f.md");
    writeFileSync(p, md);
    const parsed = parseFindingsFile(p);
    expect(parsed[0].id).toBe("F-2");
    expect(parsed[0].severity).toBe("warn");
  });
});

describe("findings gate (AC-3, AC-6)", () => {
  const seed = (root: string, severity: "block" | "warn") =>
    appendFinding(root, "GH-2", {
      fingerprint: "fp",
      stage: "verify",
      severity,
      summary: "s",
      evidence: "e",
    });

  test("AC-16: no findings file passes", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    expect(findingsGate(root, "GH-2").ok).toBe(true);
  });

  test("AC-6: an open block finding fails the gate", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "block");
    const gate = findingsGate(root, "GH-2");
    expect(gate.ok).toBe(false);
    expect(gate.blocking.map((r) => r.id)).toEqual(["F-1"]);
  });

  test("AC-6: warn severity stays open without failing", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "warn");
    expect(findingsGate(root, "GH-2").ok).toBe(true);
  });

  test("AC-4: a regressed block finding fails the gate", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "block");
    closeFinding(root, "GH-2", "F-1", { fromSensor: true });
    expect(findingsGate(root, "GH-2").ok).toBe(true);
    regressFingerprint(root, "GH-2", "fp");
    expect(findingsGate(root, "GH-2").ok).toBe(false);
  });

  test("AC-7: wontfix does not fail the gate", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "block");
    wontfixFinding(root, "GH-2", "F-1", { human: true });
    expect(findingsGate(root, "GH-2").ok).toBe(true);
  });

  test("AC-3: remediation text must cite every blocking id", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "block");
    expect(findingsGate(root, "GH-2", "no ids here").missingFromRemediation).toEqual([
      "F-1",
    ]);
    expect(findingsGate(root, "GH-2", "fixed in F-1").missingFromRemediation).toEqual(
      [],
    );
  });

  test("AC-3: F-1 is not satisfied by a mention of F-12", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-gate-"));
    seed(root, "block");
    expect(findingsGate(root, "GH-2", "see F-12").missingFromRemediation).toEqual([
      "F-1",
    ]);
  });
});
