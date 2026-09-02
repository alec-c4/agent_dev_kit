import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { loadKitProjectConfig } from "../src/kit-config.ts";

describe("kit project config", () => {
  test("defaults when missing", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    const r = loadKitProjectConfig(root);
    expect(r.path).toBeNull();
    expect(r.config.spec_language).toBe("en");
    expect(r.config.process_references).toBe("omit");
    expect(r.config.gates).toEqual([]);
    expect(r.config.wiki_index).toBe(false);
    expect(r.config.pattern_checks).toBe(true);
  });

  test("loads wiki_index true", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(join(root, ".ai", "kit.yaml"), "wiki_index: true\n");
    const r = loadKitProjectConfig(root);
    expect(r.config.wiki_index).toBe(true);
    expect(r.error).toBeUndefined();
  });

  test("ignores non-boolean wiki_index and falls back to default", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(join(root, ".ai", "kit.yaml"), "wiki_index: maybe\n");
    const r = loadKitProjectConfig(root);
    expect(r.config.wiki_index).toBe(false);
  });

  test("loads spec_language and gates", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(
      join(root, ".ai", "kit.yaml"),
      "spec_language: ru\ngates:\n  - id: duplication\n    severity: block\n",
    );
    const r = loadKitProjectConfig(root);
    expect(r.config.spec_language).toBe("ru");
    expect(r.config.process_references).toBe("omit");
    expect(r.config.gates).toEqual([{ id: "duplication", severity: "block" }]);
  });

  test("loads process_references allow", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(
      join(root, ".ai", "kit.yaml"),
      "process_references: allow\n",
    );
    const r = loadKitProjectConfig(root);
    expect(r.config.process_references).toBe("allow");
    expect(r.error).toBeUndefined();
  });

  test("rejects invalid process_references", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(
      join(root, ".ai", "kit.yaml"),
      "process_references: maybe\n",
    );
    const r = loadKitProjectConfig(root);
    expect(r.error).toContain("process_references");
    expect(r.config.process_references).toBe("omit");
  });

  test("rejects spec_locale", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(join(root, ".ai", "kit.yaml"), "spec_locale: en\n");
    const r = loadKitProjectConfig(root);
    expect(r.error).toContain("spec_language");
  });
});
