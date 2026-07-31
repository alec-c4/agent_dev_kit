import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { scanProject } from "../src/status.ts";

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
  });
});
