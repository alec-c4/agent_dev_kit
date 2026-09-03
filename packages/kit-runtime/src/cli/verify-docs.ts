#!/usr/bin/env bun
/**
 * kit verify-docs — check the external claims skills make.
 *
 *   kit verify-docs [--skill NAME] [--stale-months N] [--abandoned-months N]
 *                   [--no-links] [--json]
 *
 * Skills name packages and link to upstream documentation, and both rot without
 * anything failing. This resolves every declared package against its registry
 * and every external link, so a scheduled job can say what needs re-reading.
 */
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import {
  classify,
  parseRelease,
  parseAcceptedNames,
  parseVerifyClaims,
  registryUrl,
  type PackageResult,
} from "../doc-verify.ts";
import { findKitRoot } from "../detect-stack.ts";

const argv = process.argv.slice(2);
function arg(flag: string): string | undefined {
  const i = argv.indexOf(flag);
  if (i >= 0) return argv[i + 1];
  const hit = argv.find((a) => a.startsWith(`${flag}=`));
  return hit ? hit.slice(flag.length + 1) : undefined;
}
if (argv.includes("-h") || argv.includes("--help")) {
  console.log(
    "Usage: kit verify-docs [--skill NAME] [--stale-months N] [--abandoned-months N] [--no-links] [--json]",
  );
  process.exit(0);
}

const KIT = findKitRoot(import.meta.dir);
const only = arg("--skill");
const staleMonths = Number(arg("--stale-months") ?? 18);
const abandonedMonths = Number(arg("--abandoned-months") ?? 36);
const checkLinks = !argv.includes("--no-links");
const asJson = argv.includes("--json");
const now = new Date();

function skillFiles(): string[] {
  const out: string[] = [];
  const root = join(KIT, "skills");
  const walk = (dir: string) => {
    for (const entry of readdirSync(dir)) {
      const abs = join(dir, entry);
      if (statSync(abs).isDirectory()) walk(abs);
      else if (entry.endsWith(".md")) out.push(abs);
    }
  };
  walk(root);
  return out.filter((f) => !only || f.includes(`/${only}/`));
}

type FetchOutcome =
  | { kind: "ok"; body: unknown }
  | { kind: "absent" }        // the registry answered 404: the package is not there
  | { kind: "unreachable" };  // throttled, offline, or timed out — not a claim about the package

async function fetchJson(url: string): Promise<FetchOutcome> {
  let lastUnreachable = true;
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await Bun.sleep(400 * attempt);
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": "agent-dev-kit-verify-docs" },
        signal: AbortSignal.timeout(15_000),
      });
      if (res.status === 404) return { kind: "absent" };
      if (res.status === 429 || res.status >= 500) continue; // worth retrying
      if (!res.ok) {
        lastUnreachable = true;
        continue;
      }
      return { kind: "ok", body: await res.json() };
    } catch {
      lastUnreachable = true;
    }
  }
  return { kind: lastUnreachable ? "unreachable" : "unreachable" };
}

async function linkOk(url: string): Promise<number> {
  for (const method of ["HEAD", "GET"] as const) {
    try {
      const res = await fetch(url, {
        method,
        redirect: "follow",
        headers: { "User-Agent": "Mozilla/5.0 agent-dev-kit-verify-docs" },
        signal: AbortSignal.timeout(15_000),
      });
      if (res.ok) return res.status;
      if (method === "GET") return res.status;
    } catch {
      if (method === "GET") return 0;
    }
  }
  return 0;
}

const packages: Array<PackageResult & { skill: string }> = [];
const links: Array<{ skill: string; url: string; status: number }> = [];

/** Run tasks with a bounded pool — registries throttle, and serial is far too slow. */
async function pooled<T>(items: T[], limit: number, fn: (item: T) => Promise<void>) {
  let cursor = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (cursor < items.length) {
      const item = items[cursor++];
      await fn(item);
    }
  });
  await Promise.all(workers);
}

type ClaimTask = { skill: string; claim: ReturnType<typeof parseVerifyClaims>[number]; accepted: boolean };
const claimTasks: ClaimTask[] = [];
const linkTasks: Array<{ skill: string; url: string }> = [];

for (const file of skillFiles()) {
  const text = readFileSync(file, "utf8");
  const skill = file.slice(join(KIT, "skills").length + 1);
  const accepted = parseAcceptedNames(text);
  for (const claim of parseVerifyClaims(text)) {
    claimTasks.push({ skill, claim, accepted: accepted.has(claim.name) });
  }
  if (checkLinks) {
    const urls = [...text.matchAll(/\]\((https:\/\/[^)\s]+)\)/g)].map((m) => m[1]);
    for (const url of new Set(urls)) {
      // Placeholder hosts in worked examples are not real endpoints.
      if (/github\.com\/(org|owner)\//.test(url)) continue;
      linkTasks.push({ skill, url });
    }
  }
}

// Registries throttle aggressively; four in flight keeps the run near 20s
// without provoking 429s that would show up as false failures.
await pooled(claimTasks, 4, async ({ skill, claim, accepted }) => {
  const res = await fetchJson(registryUrl(claim));
  if (res.kind === "absent") {
    packages.push({ ...claim, skill, verdict: "missing" });
    return;
  }
  if (res.kind === "unreachable") {
    packages.push({ ...claim, skill, verdict: "unknown" });
    return;
  }
  const rel = parseRelease(claim.ecosystem, res.body);
  if (!rel) {
    packages.push({ ...claim, skill, verdict: "unknown" });
    return;
  }
  let { verdict, months } = classify(rel.released, now, staleMonths, abandonedMonths);
  if (accepted && verdict !== "current") verdict = "accepted";
  packages.push({ ...claim, skill, verdict, version: rel.version, released: rel.released, months });
});

await pooled(linkTasks, 8, async ({ skill, url }) => {
  const status = await linkOk(url);
  if (status < 200 || status >= 400) links.push({ skill, url, status });
});

packages.sort((a, b) => `${a.skill}${a.name}`.localeCompare(`${b.skill}${b.name}`));

const bad = packages.filter((p) => p.verdict === "missing" || p.verdict === "abandoned");
const warn = packages.filter((p) => p.verdict === "stale" || p.verdict === "unknown");

if (asJson) {
  console.log(JSON.stringify({ packages, links }, null, 2));
} else {
  console.log(
    `verify-docs: ${packages.length} package claim(s), ${links.length} unreachable link(s)`,
  );
  const accepted = packages.filter((p) => p.verdict === "accepted");
  for (const p of [...bad, ...warn]) {
    const age = p.months === null || p.months === undefined ? "?" : `${p.months}mo`;
    console.log(
      `  ${p.verdict.toUpperCase().padEnd(9)} ${p.ecosystem}:${p.name} (${p.version ?? "-"}, ${age}) — ${p.skill}`,
    );
  }
  for (const l of links) {
    console.log(`  LINK ${l.status || "unreachable"}  ${l.url} — ${l.skill}`);
  }
  if (accepted.length) {
    console.log(`  (${accepted.length} accepted as deliberately old)`);
  }
  const unknown = packages.filter((p) => p.verdict === "unknown").length;
  if (unknown) {
    console.log(`  (${unknown} could not be reached — not counted as failures)`);
  }
  if (!bad.length && !links.length) {
    console.log(warn.length ? "no failures; re-read the entries above" : "all claims current");
  }
}

process.exit(bad.length || links.length ? 1 : 0);
