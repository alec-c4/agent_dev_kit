import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { kitConfigPath } from "./kit-paths.ts";
import { escapeCell, splitRow } from "./md-table.ts";

export type LessonAck = "pending" | "yes";

export type Lesson = {
  id: string;
  fingerprint: string;
  stack: string;
  guide: string;
  sensor: string;
  source: string;
  added: string;
  ack: LessonAck;
  occurrences: number;
};

export type LessonInput = {
  fingerprint: string;
  stack: string;
  guide: string;
  sensor: string;
  source: string;
};

const HEADER =
  "| id | fingerprint | stack | guide | sensor | source | added | ack | occurrences |";
const DIVIDER =
  "|----|-------------|-------|-------|--------|--------|-------|-----|-------------|";

export function lessonsPath(projectRoot: string): string {
  return join(projectRoot, ".ai", "lessons.md");
}

export function defaultGlobalLessonsPath(): string {
  return kitConfigPath("lessons.yaml");
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

export function parseLessonsMarkdown(text: string): Lesson[] {
  const rows: Lesson[] = [];
  let seenHeader = false;
  for (const line of text.split("\n")) {
    const cells = splitRow(line);
    if (cells.length < 8) continue;
    if (cells[0] === "id") {
      seenHeader = true;
      continue;
    }
    if (!seenHeader || !/^L-\d+$/.test(cells[0])) continue;
    rows.push({
      id: cells[0],
      fingerprint: cells[1],
      stack: cells[2],
      guide: cells[3],
      sensor: cells[4],
      source: cells[5] ?? "",
      added: cells[6] ?? "",
      ack: cells[7] === "yes" ? "yes" : "pending",
      occurrences: Number(cells[8] || "1") || 1,
    });
  }
  return rows;
}

function serialize(rows: Lesson[]): string {
  const lines = ["# Lessons", "", HEADER, DIVIDER];
  for (const r of rows) {
    lines.push(
      `| ${[
        r.id,
        escapeCell(r.fingerprint),
        escapeCell(r.stack),
        escapeCell(r.guide),
        escapeCell(r.sensor),
        escapeCell(r.source),
        r.added,
        r.ack,
        String(r.occurrences),
      ].join(" | ")} |`,
    );
  }
  lines.push("");
  return lines.join("\n");
}

function load(projectRoot: string): Lesson[] {
  const path = lessonsPath(projectRoot);
  if (!existsSync(path)) return [];
  return parseLessonsMarkdown(readFileSync(path, "utf8"));
}

function save(projectRoot: string, rows: Lesson[]): void {
  const path = lessonsPath(projectRoot);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, serialize(rows));
}

function nextId(rows: Lesson[]): string {
  let max = 0;
  for (const r of rows) {
    const n = Number(r.id.replace(/^L-/, ""));
    if (Number.isFinite(n) && n > max) max = n;
  }
  return `L-${max + 1}`;
}

export function proposeLesson(projectRoot: string, input: LessonInput): Lesson {
  const rows = load(projectRoot);
  const existing = rows.find((r) => r.fingerprint === input.fingerprint);
  if (existing) {
    existing.occurrences += 1;
    if (existing.occurrences >= 2) existing.ack = "yes";
    save(projectRoot, rows);
    return existing;
  }
  const row: Lesson = {
    id: nextId(rows),
    fingerprint: input.fingerprint,
    stack: input.stack || "*",
    guide: input.guide,
    sensor: input.sensor,
    source: input.source,
    added: today(),
    ack: "pending",
    occurrences: 1,
  };
  rows.push(row);
  save(projectRoot, rows);
  return row;
}

export function ackLesson(projectRoot: string, id: string): Lesson {
  const rows = load(projectRoot);
  const row = rows.find((r) => r.id === id);
  if (!row) throw new Error(`lesson ${id} not found`);
  row.ack = "yes";
  save(projectRoot, rows);
  return row;
}

export type GlobalLesson = {
  fingerprint: string;
  stack: string;
  guide: string;
  sensor: string;
  added: string;
};

function parseGlobalYaml(text: string): GlobalLesson[] {
  const parsed = (Bun.YAML.parse(text) as { lessons?: GlobalLesson[] } | null) ?? {};
  const list = Array.isArray(parsed.lessons) ? parsed.lessons : [];
  return list.filter(
    (l) => l && typeof l.fingerprint === "string" && typeof l.guide === "string",
  );
}

function serializeGlobal(rows: GlobalLesson[]): string {
  const lines = ["lessons:"];
  if (!rows.length) {
    lines.push("  []");
    return `${lines.join("\n")}\n`;
  }
  for (const r of rows) {
    lines.push(`  - fingerprint: ${JSON.stringify(r.fingerprint)}`);
    lines.push(`    stack: ${JSON.stringify(r.stack)}`);
    lines.push(`    guide: ${JSON.stringify(r.guide)}`);
    lines.push(`    sensor: ${JSON.stringify(r.sensor)}`);
    lines.push(`    added: ${JSON.stringify(r.added)}`);
  }
  return `${lines.join("\n")}\n`;
}

export function promoteLessonToGlobal(
  projectRoot: string,
  id: string,
  globalPath: string,
): GlobalLesson {
  const rows = load(projectRoot);
  const row = rows.find((r) => r.id === id);
  if (!row) throw new Error(`lesson ${id} not found`);
  if (row.ack !== "yes") throw new Error(`lesson ${id} is not acknowledged`);
  const existing = existsSync(globalPath)
    ? parseGlobalYaml(readFileSync(globalPath, "utf8"))
    : [];
  const entry: GlobalLesson = {
    fingerprint: row.fingerprint,
    stack: row.stack,
    guide: row.guide,
    sensor: row.sensor,
    added: today(),
  };
  const next = existing.filter((e) => e.fingerprint !== entry.fingerprint);
  next.push(entry);
  mkdirSync(dirname(globalPath), { recursive: true });
  writeFileSync(globalPath, serializeGlobal(next));
  return entry;
}

export function loadLessonsForSession(
  projectRoot: string,
  detectedStack: string,
  globalPath?: string,
  cap = 20,
): Lesson[] {
  const project = load(projectRoot).filter((r) => r.ack === "yes");
  const global: Lesson[] = [];
  if (globalPath && existsSync(globalPath)) {
    for (const g of parseGlobalYaml(readFileSync(globalPath, "utf8"))) {
      global.push({
        id: `G-${g.fingerprint}`,
        fingerprint: g.fingerprint,
        stack: g.stack,
        guide: g.guide,
        sensor: g.sensor,
        source: "",
        added: g.added,
        ack: "yes",
        occurrences: 1,
      });
    }
  }
  const stack = detectedStack || "*";
  const merged = [...project, ...global].filter((r) => {
    if (stack === "*") return true;
    return r.stack === "*" || r.stack === stack;
  });
  merged.sort((a, b) => (a.added < b.added ? 1 : a.added > b.added ? -1 : 0));
  const seen = new Set<string>();
  const deduped: Lesson[] = [];
  for (const row of merged) {
    if (seen.has(row.fingerprint)) continue;
    seen.add(row.fingerprint);
    deduped.push(row);
  }
  return deduped.slice(0, cap);
}
