import { describe, expect, test } from "bun:test";
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  formatProjectsYaml,
  loadProjects,
  pruneProjects,
  saveProjects,
  type ProjectsFile,
} from "../src/projects-registry.ts";

describe("projects registry YAML", () => {
  test("formatProjectsYaml emits block style, not flow JSON", () => {
    const data: ProjectsFile = {
      version: 1,
      projects: [
        {
          id: "demo",
          path: "/tmp/demo",
          added_at: "2026-07-31T08:00:00.000Z",
          last_seen_at: "2026-07-31T09:00:00.000Z",
        },
      ],
    };
    const yaml = formatProjectsYaml(data);
    expect(yaml).toContain("version: 1\n");
    expect(yaml).toContain("projects:\n");
    expect(yaml).toContain("  - id: demo\n");
    expect(yaml).toContain("    path: /tmp/demo\n");
    expect(yaml.startsWith("{")).toBe(false);
    expect(Bun.YAML.parse(yaml)).toEqual(data);
  });

  test("saveProjects round-trips block YAML", () => {
    const dir = mkdtempSync(join(tmpdir(), "kit-proj-"));
    const file = join(dir, "projects.yaml");
    // Pretend path exists for prune: write a marker dir
    const projectPath = dir;
    const data: ProjectsFile = {
      version: 1,
      projects: [
        {
          id: "x",
          path: projectPath,
          added_at: "2026-07-31T08:00:00.000Z",
          last_seen_at: "2026-07-31T09:00:00.000Z",
        },
      ],
    };
    saveProjects(file, data);
    const raw = readFileSync(file, "utf8");
    expect(raw.startsWith("{")).toBe(false);
    expect(raw).toContain("  - id: x\n");
    expect(loadProjects(file).projects[0].id).toBe("x");
  });

  test("loadProjects still accepts legacy flow-style file", () => {
    const dir = mkdtempSync(join(tmpdir(), "kit-proj-legacy-"));
    const file = join(dir, "projects.yaml");
    writeFileSync(
      file,
      `{version: 1,projects: [{id: legacy,path: ${JSON.stringify(dir)},added_at: "2026-01-01T00:00:00.000Z",last_seen_at: "2026-01-01T00:00:00.000Z"}]}\n`,
    );
    const loaded = loadProjects(file);
    expect(loaded.projects[0].id).toBe("legacy");
  });
});

describe("prune safety", () => {
  test("drops a deleted project whose parent is still mounted", () => {
    const base = mkdtempSync(join(tmpdir(), "kit-reg-"));
    const gone = join(base, "deleted-project");
    const data = pruneProjects({
      version: 1,
      projects: [
        { id: "gone", path: gone, added_at: "t", last_seen_at: "t" },
      ],
    });
    expect(data.projects).toHaveLength(0);
  });

  test("keeps a project under an unreachable parent (unmounted volume)", () => {
    const data = pruneProjects({
      version: 1,
      projects: [
        {
          id: "ext",
          path: "/Volumes/NotMounted/work/app",
          added_at: "t",
          last_seen_at: "t",
        },
      ],
    });
    expect(data.projects.map((p) => p.id)).toEqual(["ext"]);
  });
});

