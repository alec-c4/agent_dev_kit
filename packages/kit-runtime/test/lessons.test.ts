import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  ackLesson,
  loadLessonsForSession,
  lessonsPath,
  parseLessonsMarkdown,
  promoteLessonToGlobal,
  proposeLesson,
} from "../src/lessons.ts";

describe("lessons (AC-8, AC-9, AC-10)", () => {
  test("AC-9: load at most 20 newest matching stack or *", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-les-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    const lines = [
      "# Lessons",
      "",
      "| id | fingerprint | stack | guide | sensor | source | added | ack | occurrences |",
      "|----|-------------|-------|-------|--------|--------|-------|-----|-------------|",
    ];
    for (let i = 1; i <= 25; i++) {
      const day = String(i).padStart(2, "0");
      lines.push(
        `| L-${i} | fp-${i} | rails | g${i} | check-patterns | GH-1 F-1 | 2026-08-${day} | yes | 1 |`,
      );
    }
    lines.push(
      `| L-99 | other | python | no | check-patterns | GH-2 F-1 | 2026-08-28 | yes | 1 |`,
    );
    writeFileSync(lessonsPath(root), lines.join("\n"));
    const loaded = loadLessonsForSession(root, "rails");
    expect(loaded).toHaveLength(20);
    expect(loaded.some((l) => l.stack === "python")).toBe(false);
    expect(loaded[0].id).toBe("L-25");
  });

  test("AC-8: first propose is pending; second auto-acks", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-les-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    const first = proposeLesson(root, {
      fingerprint: "shipped-process-language",
      stack: "*",
      guide: "Keep process jargon out of shipped docs",
      sensor: "check-patterns",
      source: "GH-1 F-1",
    });
    expect(first.ack).toBe("pending");
    const second = proposeLesson(root, {
      fingerprint: "shipped-process-language",
      stack: "*",
      guide: "Keep process jargon out of shipped docs",
      sensor: "check-patterns",
      source: "GH-2 F-1",
    });
    expect(second.ack).toBe("yes");
    expect(second.occurrences).toBe(2);
  });

  test("a pipe in the guide does not shift columns", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-lesson-"));
    proposeLesson(root, {
      fingerprint: "fp-pipe",
      stack: "rails",
      guide: "prefer a || b | never c",
      sensor: "check-patterns",
      source: "GH-1 F-2",
    });
    const rows = parseLessonsMarkdown(readFileSync(lessonsPath(root), "utf8"));
    expect(rows).toHaveLength(1);
    expect(rows[0].guide).toBe("prefer a || b | never c");
    expect(rows[0].sensor).toBe("check-patterns");
    expect(rows[0].source).toBe("GH-1 F-2");
    expect(rows[0].ack).toBe("pending");
    expect(rows[0].occurrences).toBe(1);
  });

  test("ackLesson flips pending to yes", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-les-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    const row = proposeLesson(root, {
      fingerprint: "x",
      stack: "*",
      guide: "g",
      sensor: "s",
      source: "GH-1 F-1",
    });
    ackLesson(root, row.id);
    expect(loadLessonsForSession(root, "*").find((l) => l.id === row.id)?.ack).toBe(
      "yes",
    );
  });

  test("AC-10: promote copies fingerprint guide sensor only", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-les-"));
    const globalDir = mkdtempSync(join(tmpdir(), "kit-glob-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    const row = proposeLesson(root, {
      fingerprint: "shipped-process-language",
      stack: "rails",
      guide: "Keep process jargon out of shipped docs",
      sensor: "check-patterns",
      source: "secret-app GH-1 F-1",
    });
    ackLesson(root, row.id);
    const globalPath = join(globalDir, "lessons.yaml");
    promoteLessonToGlobal(root, row.id, globalPath);
    const yaml = readFileSync(globalPath, "utf8");
    expect(yaml).toContain("shipped-process-language");
    expect(yaml).toContain("check-patterns");
    expect(yaml).not.toContain("secret-app");
    const merged = loadLessonsForSession(root, "rails", globalPath);
    expect(merged.some((l) => l.fingerprint === "shipped-process-language")).toBe(
      true,
    );
  });
});
