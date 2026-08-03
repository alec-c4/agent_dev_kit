import { describe, expect, test } from "bun:test";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { detect, kitDirFromImportMeta } from "../src/detect-stack.ts";

const kit = kitDirFromImportMeta(import.meta.url);
const fixtures = [
  "minimal-rails",
  "minimal-elixir",
  "minimal-swift",
  "minimal-kotlin",
  "minimal-react-native",
  "minimal-flutter",
] as const;

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
  for (const name of fixtures) {
    test(`${name}: Bun matches Python (sans detected_at)`, () => {
      const cwd = resolve(kit, "scripts/fixtures", name);
      const bunProfile = detect(cwd, kit);
      const pyProfile = pythonDetect(cwd);
      expect(withoutDetectedAt(bunProfile)).toEqual(withoutDetectedAt(pyProfile));
      expect(bunProfile.primary_stack).toBeTruthy();
    });
  }
});