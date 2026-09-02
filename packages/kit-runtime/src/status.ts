import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { basename, join } from "node:path";
import { countOpenFindings, findingsPath } from "./findings.ts";

export const PIPELINE_STAGES = [
  "intake",
  "spec",
  "plan",
  "implement",
  "comprehension",
  "verify",
  "review",
  "done",
] as const;

export type PipelineStage = (typeof PIPELINE_STAGES)[number];

export type WorkStatus = {
  project: string;
  project_path: string;
  work_ref: string;
  spec_key: string | null;
  stage: PipelineStage;
  artifacts: string[];
  updated_at: string | null;
  open_findings: number;
};

function readHeader(path: string): Record<string, string> {
  if (!existsSync(path)) return {};
  const text = readFileSync(path, "utf8");
  const out: Record<string, string> = {};
  for (const line of text.split("\n").slice(0, 40)) {
    const m = line.match(/^\*\*([^*]+):\*\*\s*(.+)\s*$/);
    if (m) out[m[1].trim().toLowerCase()] = m[2].trim();
  }
  return out;
}

function mtimeIso(path: string): string | null {
  try {
    return statSync(path).mtime.toISOString();
  } catch {
    return null;
  }
}

function inferStage(aiRoot: string, workRef: string): {
  stage: PipelineStage;
  artifacts: string[];
  updated_at: string | null;
  spec_key: string | null;
} {
  const workDir = join(aiRoot, "work");
  const analysis = join(workDir, `${workRef}-analysis.md`);
  const plan = join(workDir, `${workRef}-plan.md`);
  const handoff = join(workDir, `${workRef}-handoff.md`);
  const verification = join(workDir, `${workRef}-verification.md`);
  const prSummary = join(aiRoot, "pr-summary.md");

  const artifacts: string[] = [];
  let updated: string | null = null;
  const touch = (p: string) => {
    if (!existsSync(p)) return;
    artifacts.push(p);
    const t = mtimeIso(p);
    if (t && (!updated || t > updated)) updated = t;
  };

  touch(analysis);
  touch(plan);
  touch(handoff);
  touch(verification);
  touch(findingsPath(join(aiRoot, ".."), workRef));

  const headers = {
    ...readHeader(analysis),
    ...readHeader(plan),
  };
  let specKey =
    headers["spec key"]?.replace(/[`|]/g, "").trim() ||
    headers["spec_key"]?.replace(/[`|]/g, "").trim() ||
    null;

  let specPath: string | null = null;
  if (specKey) {
    const candidate = join(aiRoot, "specs", `${specKey}-spec.md`);
    if (existsSync(candidate)) specPath = candidate;
  }
  const specsDir = join(aiRoot, "specs");
  if (!specPath && existsSync(specsDir)) {
    for (const f of readdirSync(specsDir)) {
      if (!f.endsWith("-spec.md")) continue;
      const p = join(specsDir, f);
      const h = readHeader(p);
      const wr = (h["work ref"] || h["work_ref"] || "").replace(/[`|]/g, "").trim();
      // An empty work ref must not match — `workRef.includes("")` is always true
      // and would bind the first spec in the tree to every work item.
      if (!wr || wr === "—" || wr === "-") continue;
      const wrHead = wr.split(/\s/)[0];
      if (wr === workRef || wrHead === workRef) {
        specPath = p;
        specKey = f.replace(/-spec\.md$/, "");
        break;
      }
    }
  }
  if (specPath) touch(specPath);

  const specHeaders = specPath ? readHeader(specPath) : {};
  const status = (specHeaders["status"] || "").toLowerCase();
  const approved = status.includes("approved");
  const handoffText = existsSync(handoff) ? readFileSync(handoff, "utf8") : "";
  const signedOff =
    /##\s*Human sign-off/i.test(handoffText) &&
    (/\[x\]/i.test(handoffText) || /signed-off|sign-off:\s*yes/i.test(handoffText));
  const verHeaders = readHeader(verification);
  const verdict = (verHeaders["verdict"] || "").toUpperCase();
  const hasPr = existsSync(prSummary);

  let stage: PipelineStage = "intake";
  if (hasPr && verdict.includes("PASS")) stage = "done";
  else if (existsSync(verification) && verdict.includes("PASS")) stage = "review";
  else if (existsSync(verification) && verdict.includes("FAIL")) stage = "implement";
  else if (existsSync(verification)) stage = "verify";
  else if (signedOff) stage = "verify";
  else if (existsSync(handoff)) stage = "comprehension";
  else if (existsSync(plan) && approved) stage = "implement";
  else if (existsSync(plan)) stage = "plan";
  else if (specPath && approved) stage = "plan";
  else if (specPath) stage = "spec";
  else if (existsSync(analysis)) stage = "intake";

  return { stage, artifacts, updated_at: updated, spec_key: specKey };
}

function listWorkRefs(aiRoot: string): string[] {
  const workDir = join(aiRoot, "work");
  if (!existsSync(workDir)) return [];
  const refs = new Set<string>();
  for (const f of readdirSync(workDir)) {
    const m = f.match(/^(.+)-(analysis|plan|handoff|verification|findings)\.md$/);
    if (m) refs.add(m[1]);
  }
  return [...refs].sort();
}

export function scanProject(projectPath: string, projectId?: string): WorkStatus[] {
  const aiRoot = join(projectPath, ".ai");
  if (!existsSync(aiRoot)) return [];
  const id = projectId || basename(projectPath);
  return listWorkRefs(aiRoot).map((work_ref) => {
    const inferred = inferStage(aiRoot, work_ref);
    return {
      project: id,
      project_path: projectPath,
      work_ref,
      spec_key: inferred.spec_key,
      stage: inferred.stage,
      artifacts: inferred.artifacts,
      updated_at: inferred.updated_at,
      open_findings: countOpenFindings(projectPath, work_ref),
    };
  });
}

export function formatStatusTable(rows: WorkStatus[]): string {
  if (!rows.length) return "(no work items found under .ai/work)";
  const lines = ["PROJECT\tWORK_REF\tSTAGE\tSPEC_KEY\tOPEN_FINDINGS\tUPDATED"];
  for (const r of rows) {
    lines.push(
      [
        r.project,
        r.work_ref,
        r.stage,
        r.spec_key || "-",
        String(r.open_findings),
        r.updated_at || "-",
      ].join("\t"),
    );
  }
  return lines.join("\n");
}
