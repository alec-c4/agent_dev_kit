#!/usr/bin/env bun
/**
 * kit-status — scan .ai/ work items; optional --watch and --json.
 * Also upserts the current project into the global projects registry.
 * Honors `.ai/kit.yaml` (`spec_language`, `process_references`, `gates`, `wiki_index`); rejects `spec_locale`.
 */
import { resolve } from "node:path";
import { watch } from "node:fs";
import {
  defaultProjectsPath,
  loadProjects,
  upsertProject,
} from "../projects-registry.ts";
import { loadKitProjectConfig } from "../kit-config.ts";
import { formatStatusTable, scanProject, type WorkStatus } from "../status.ts";

const args = process.argv.slice(2);
let project = process.cwd();
let json = false;
let watchMode = false;
let all = false;
const registryPath = defaultProjectsPath();

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "--json") json = true;
  else if (a === "--watch") watchMode = true;
  else if (a === "--all") all = true;
  else if (a === "--project") project = resolve(args[++i] ?? ".");
  else if (a === "-h" || a === "--help") {
    console.log(
      "Usage: kit-status [--project PATH] [--all] [--json] [--watch]\n" +
        "  --all     scan all projects in ~/.config/agent-dev-kit/projects.yaml\n" +
        "  --watch   reprint on .ai/ changes (single project)",
    );
    process.exit(0);
  }
}

function collect(): WorkStatus[] {
  if (all) {
    const data = loadProjects(registryPath);
    return data.projects.flatMap((p) => scanProject(p.path, p.id));
  }
  upsertProject(registryPath, project);
  return scanProject(project);
}

function emit(rows: WorkStatus[]) {
  const kit = loadKitProjectConfig(all ? process.cwd() : project);
  if (kit.error) {
    console.error(`warning: ${kit.error}`);
  }
  if (json) {
    console.log(
      JSON.stringify(
        {
          spec_language: kit.config.spec_language,
          process_references: kit.config.process_references,
          gates: kit.config.gates,
          wiki_index: kit.config.wiki_index,
          kit_yaml: kit.path,
          work: rows,
        },
        null,
        2,
      ),
    );
    return;
  }
  const gateIds = kit.config.gates.map((g) =>
    g.severity ? `${g.id}:${g.severity}` : g.id,
  );
  console.error(
    `spec_language=${kit.config.spec_language}` +
      ` process_references=${kit.config.process_references}` +
      (gateIds.length ? ` gates=[${gateIds.join(", ")}]` : " gates=[]") +
      ` wiki_index=${kit.config.wiki_index}`,
  );
  console.log(formatStatusTable(rows));
}

emit(collect());

if (watchMode) {
  if (all) {
    console.error("--watch with --all is not supported yet; watching cwd project only");
  }
  const ai = resolve(project, ".ai");
  console.error(`watching ${ai} …`);
  try {
    watch(ai, { recursive: true }, () => {
      console.log("---");
      emit(collect());
    });
  } catch (e) {
    console.error(`watch failed: ${e}`);
    process.exit(1);
  }
}
