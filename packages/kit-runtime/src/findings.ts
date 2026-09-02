import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { escapeCell, splitRow } from "./md-table.ts";

export type FindingStatus = "open" | "closed" | "regressed" | "wontfix";
export type FindingSeverity = "block" | "warn";

export type Finding = {
  id: string;
  fingerprint: string;
  stage: string;
  severity: FindingSeverity;
  status: FindingStatus;
  summary: string;
  evidence: string;
  opened: string;
  closed: string;
};

export type FindingInput = {
  fingerprint: string;
  stage: string;
  severity: FindingSeverity;
  summary: string;
  evidence: string;
};

const HEADER =
  "| id | fingerprint | stage | severity | status | summary | evidence | opened | closed |";
const DIVIDER =
  "|----|-------------|-------|----------|--------|---------|----------|--------|--------|";

export function findingsPath(projectRoot: string, workRef: string): string {
  return join(projectRoot, ".ai", "work", `${workRef}-findings.md`);
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

export function parseFindingsMarkdown(text: string): Finding[] {
  const lines = text.split("\n");
  const rows: Finding[] = [];
  let seenHeader = false;
  for (const line of lines) {
    if (!line.includes("|")) continue;
    const cells = splitRow(line);
    if (cells.length < 8) continue;
    if (cells[0] === "id" && cells[1] === "fingerprint") {
      seenHeader = true;
      continue;
    }
    if (cells[0].match(/^-+$/)) continue;
    if (!seenHeader) continue;
    if (!/^F-\d+$/.test(cells[0])) continue;
    const severity: FindingSeverity = cells[3] === "warn" ? "warn" : "block";
    const statusRaw = cells[4];
    const status: FindingStatus =
      statusRaw === "closed" ||
      statusRaw === "regressed" ||
      statusRaw === "wontfix"
        ? statusRaw
        : "open";
    rows.push({
      id: cells[0],
      fingerprint: cells[1],
      stage: cells[2],
      severity,
      status,
      summary: cells[5] ?? "",
      evidence: cells[6] ?? "",
      opened: cells[7] ?? "",
      closed: cells[8] ?? "",
    });
  }
  return rows;
}

export function parseFindingsFile(path: string): Finding[] {
  if (!existsSync(path)) return [];
  return parseFindingsMarkdown(readFileSync(path, "utf8"));
}

export function serializeFindings(workRef: string, rows: Finding[]): string {
  const lines = [
    `# Findings: ${workRef}`,
    "",
    HEADER,
    DIVIDER,
  ];
  for (const r of rows) {
    lines.push(
      `| ${[
        r.id,
        escapeCell(r.fingerprint),
        escapeCell(r.stage),
        r.severity,
        r.status,
        escapeCell(r.summary),
        escapeCell(r.evidence),
        r.opened,
        r.closed,
      ].join(" | ")} |`,
    );
  }
  lines.push("");
  return lines.join("\n");
}

function writeRows(projectRoot: string, workRef: string, rows: Finding[]): void {
  const path = findingsPath(projectRoot, workRef);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, serializeFindings(workRef, rows));
}

function load(projectRoot: string, workRef: string): Finding[] {
  return parseFindingsFile(findingsPath(projectRoot, workRef));
}

function nextId(rows: Finding[]): string {
  let max = 0;
  for (const r of rows) {
    const n = Number(r.id.replace(/^F-/, ""));
    if (Number.isFinite(n) && n > max) max = n;
  }
  return `F-${max + 1}`;
}

export function appendFinding(
  projectRoot: string,
  workRef: string,
  input: FindingInput,
): Finding {
  const rows = load(projectRoot, workRef);
  const existing = rows.find(
    (r) =>
      r.fingerprint === input.fingerprint &&
      (r.status === "open" || r.status === "regressed"),
  );
  if (existing) {
    existing.evidence = input.evidence;
    existing.summary = input.summary;
    existing.stage = input.stage;
    existing.severity = input.severity;
    writeRows(projectRoot, workRef, rows);
    return existing;
  }
  const row: Finding = {
    id: nextId(rows),
    fingerprint: input.fingerprint,
    stage: input.stage,
    severity: input.severity,
    status: "open",
    summary: input.summary,
    evidence: input.evidence,
    opened: today(),
    closed: "",
  };
  rows.push(row);
  writeRows(projectRoot, workRef, rows);
  return row;
}

export function closeFinding(
  projectRoot: string,
  workRef: string,
  id: string,
  opts: { fromSensor: boolean },
): Finding {
  if (!opts.fromSensor) {
    throw new Error("close requires --from-sensor (writers cannot close findings)");
  }
  const rows = load(projectRoot, workRef);
  const row = rows.find((r) => r.id === id);
  if (!row) throw new Error(`finding ${id} not found`);
  row.status = "closed";
  row.closed = today();
  writeRows(projectRoot, workRef, rows);
  return row;
}

export function wontfixFinding(
  projectRoot: string,
  workRef: string,
  id: string,
  opts: { human: boolean },
): Finding {
  if (!opts.human) {
    throw new Error("wontfix requires --human");
  }
  const rows = load(projectRoot, workRef);
  const row = rows.find((r) => r.id === id);
  if (!row) throw new Error(`finding ${id} not found`);
  row.status = "wontfix";
  row.closed = today();
  writeRows(projectRoot, workRef, rows);
  return row;
}

/** AC-4: closed fingerprint seen again → regressed. Returns true if a row changed. */
export function regressFingerprint(
  projectRoot: string,
  workRef: string,
  fingerprint: string,
): boolean {
  const rows = load(projectRoot, workRef);
  let changed = false;
  for (const row of rows) {
    if (row.fingerprint === fingerprint && row.status === "closed") {
      row.status = "regressed";
      row.closed = "";
      changed = true;
    }
  }
  if (changed) writeRows(projectRoot, workRef, rows);
  return changed;
}

export function countOpenFindings(projectRoot: string, workRef: string): number {
  return load(projectRoot, workRef).filter(
    (r) => r.status === "open" || r.status === "regressed",
  ).length;
}

export type FindingsGateResult = {
  ok: boolean;
  blocking: Finding[];
  missingFromRemediation: string[];
};

/**
 * AC-3 + AC-6: verification fails while a `block` finding is open or
 * regressed, and while a remediation text does not cite every such id.
 * Pass `remediationText` (plan or change-set body) to check AC-3 too.
 */
export function findingsGate(
  projectRoot: string,
  workRef: string,
  remediationText?: string,
): FindingsGateResult {
  const blocking = load(projectRoot, workRef).filter(
    (r) =>
      r.severity === "block" && (r.status === "open" || r.status === "regressed"),
  );
  const missingFromRemediation =
    remediationText === undefined
      ? []
      : blocking
          .filter((r) => !new RegExp(`\\b${r.id}\\b`).test(remediationText))
          .map((r) => r.id);
  return {
    ok: blocking.length === 0 && missingFromRemediation.length === 0,
    blocking,
    missingFromRemediation,
  };
}

export function blockingOpenIds(projectRoot: string, workRef: string): string[] {
  return findingsGate(projectRoot, workRef).blocking.map((r) => r.id);
}
