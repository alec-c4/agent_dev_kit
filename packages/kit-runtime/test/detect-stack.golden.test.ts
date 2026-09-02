import { describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { detect, kitDirFromImportMeta } from "../src/detect-stack.ts";

const kit = kitDirFromImportMeta(import.meta.url);
/** Fixture directory → the stack `detection_order` must resolve it to. */
const fixtures: Record<string, string> = {
  "minimal-rails": "rails",
  "minimal-elixir": "elixir",
  "minimal-swift": "swift",
  "minimal-kotlin": "kotlin",
  "minimal-react-native": "react-native",
  "minimal-flutter": "flutter",
  "minimal-node": "node",
  // `files` is an AND match: these once required every listed file at once and
  // resolved to null. `tauri` sat after `node`, so it never won on a repo with
  // a package.json.
  "minimal-fastapi": "fastapi",
  "minimal-django": "django",
  "minimal-flask": "flask",
  "minimal-python": "python",
  "minimal-tauri": "tauri",
};

function pythonDetect(fixtureDir: string): Record<string, unknown> {
  const r = spawnSync(
    "python3",
    [
      resolve(kit, "scripts/detect_stack.py"),
      "--cwd",
      fixtureDir,
      "--kit-dir",
      kit,
    ],
    { encoding: "utf8" },
  );
  if (r.status !== 0 && !r.stdout) {
    throw new Error(`python detect failed: ${r.stderr}`);
  }
  return JSON.parse(r.stdout) as Record<string, unknown>;
}

function withoutDetectedAt(profile: Record<string, unknown>): Record<string, unknown> {
  const { detected_at: _, ...rest } = profile;
  return rest;
}

describe("detect-stack golden parity", () => {
  for (const [name, expected] of Object.entries(fixtures)) {
    test(`${name}: resolves to ${expected}, Bun matches Python`, () => {
      const cwd = resolve(kit, "scripts/fixtures", name);
      const bunProfile = detect(cwd, kit);
      const pyProfile = pythonDetect(cwd);
      expect(withoutDetectedAt(bunProfile)).toEqual(withoutDetectedAt(pyProfile));
      expect(bunProfile.primary_stack).toBe(expected);
    });
  }
});