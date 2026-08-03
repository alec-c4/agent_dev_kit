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
    expect(r.config.gates).toEqual([]);
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
    expect(r.config.gates).toEqual([{ id: "duplication", severity: "block" }]);
  });

  test("rejects spec_locale", () => {
    const root = mkdtempSync(join(tmpdir(), "kit-cfg-"));
    mkdirSync(join(root, ".ai"), { recursive: true });
    writeFileSync(join(root, ".ai", "kit.yaml"), "spec_locale: en\n");
    const r = loadKitProjectConfig(root);
    expect(r.error).toContain("spec_language");
  });
});
