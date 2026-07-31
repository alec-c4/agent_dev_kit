#!/usr/bin/env bun
/**
 * Snapshot GitHub issues to .ai/tracker-cache.json
 * Usage: bun sync-tracker-cache.ts <projectDir> [--dry-run]
 */
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { loadTrackerConfig } from "../tracker-config.ts";

const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const projectDir = resolve(args.find((a) => !a.startsWith("--")) || process.cwd());
const cfg = loadTrackerConfig(projectDir);

function fail(msg: string): never {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

const provider = cfg.provider || "none";
if (!existsSync(join(projectDir, ".ai", "tracker.yaml"))) {
  // match python: default provider github when no yaml — actually python sets github if no file
}
const effectiveProvider =
  existsSync(join(projectDir, ".ai", "tracker.yaml")) ? provider : "github";

if (effectiveProvider === "none") {
  fail("tracker provider is none — set provider: github in .ai/tracker.yaml");
}
if (effectiveProvider === "linear" || effectiveProvider === "jira") {
  fail(
    `provider '${effectiveProvider}' cache sync not implemented — use paste intake (TRACKER.md)`,
  );
}
if (effectiveProvider !== "github") {
  fail(`unknown tracker provider: ${effectiveProvider}`);
}

const auth = Bun.spawnSync(["gh", "auth", "status"], { stdout: "pipe", stderr: "pipe" });
if (auth.exitCode !== 0) {
  fail("gh CLI required and authenticated — run: gh auth login");
}

const maxItems = Number(cfg.cache_max_items || 50);
const statuses = (cfg.cache_statuses || ["open"]).map((s) => String(s).toLowerCase());
const workRefFormat = cfg.work_ref_format || "GH-{n}";

const list = Bun.spawnSync(
  [
    "gh",
    "issue",
    "list",
    "--state",
    "open",
    "--limit",
    String(maxItems),
    "--json",
    "number,title,state,url",
  ],
  { cwd: projectDir, stdout: "pipe", stderr: "pipe" },
);
if (list.exitCode !== 0) {
  fail("gh issue list failed — check repo context and gh auth");
}

const issues = JSON.parse(list.stdout.toString()) as Array<{
  number: number;
  title?: string;
  state?: string;
  url?: string;
}>;

const items = [];
for (const issue of issues) {
  const state = (issue.state || "").toLowerCase();
  if (statuses.length && !statuses.includes(state)) continue;
  const num = String(issue.number);
  items.push({
    work_ref: workRefFormat.replace("{n}", num),
    external_id: num,
    title: issue.title || "",
    status: issue.state || "",
    url: issue.url || "",
  });
}

const cacheRel = cfg.cache_file.startsWith(".ai/")
  ? cfg.cache_file
  : join(".ai", cfg.cache_file);
const output = join(projectDir, cacheRel);

const payload = {
  version: 1,
  synced_at: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
  provider: effectiveProvider,
  items,
};

if (dryRun) {
  console.log(`Would write: ${output}`);
  console.log(JSON.stringify(payload, null, 2));
  process.exit(0);
}

mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, JSON.stringify(payload, null, 2) + "\n");
console.log(`Wrote ${output} (${items.length} items)`);
