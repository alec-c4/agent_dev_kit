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
  classifyLink,
  isRetryableStatus,
  parseRelease,
  parseAcceptedNames,
  parseVerifyClaims,
  registryUrl,
  type LinkVerdict,
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
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await Bun.sleep(400 * attempt);
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": "agent-dev-kit-verify-docs" },
        signal: AbortSignal.timeout(15_000),
      });
      if (res.status === 404) return { kind: "absent" };
      if (isRetryableStatus(res.status)) continue;
      if (!res.ok) continue;
      return { kind: "ok", body: await res.json() };
    } catch {
      // Timeout or transport error — retry, then report unreachable.
    }
  }
  return { kind: "unreachable" };
}

/**
 * HEAD first because it is cheap, GET as the fallback for hosts that refuse
 * HEAD. Retries on a throttle or a 5xx: a shared CI runner gets rate-limited
 * by busy documentation hosts, and one 429 is not a dead link.
 */
async function checkLink(url: string): Promise<{ verdict: LinkVerdict; status: number }> {
  let status = 0;
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await Bun.sleep(500 * attempt);
    for (const method of ["HEAD", "GET"] as const) {
      try {
        const res = await fetch(url, {
          method,
          redirect: "follow",
          headers: { "User-Agent": "Mozilla/5.0 agent-dev-kit-verify-docs" },
          signal: AbortSignal.timeout(15_000),
        });
        status = res.status;
        if (res.ok) return { verdict: "ok", status };
        if (classifyLink(status) === "dead") return { verdict: "dead", status };
      } catch {
        status = 0;
      }
    }
    if (status !== 0 && !isRetryableStatus(status)) break;
  }
  return { verdict: classifyLink(status), status };
}

const packages: Array<PackageResult & { skill: string }> = [];
const links: Array<{ skills: string[]; url: string; status: number; verdict: LinkVerdict }> = [];

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
// One URL, one request, however many skills cite it.
const linkRefs = new Map<string, Set<string>>();

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
      const refs = linkRefs.get(url) ?? new Set<string>();
      refs.add(skill);
      linkRefs.set(url, refs);
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

await pooled([...linkRefs.keys()], 4, async (url) => {
  const { verdict, status } = await checkLink(url);
  if (verdict === "ok") return;
  links.push({ skills: [...(linkRefs.get(url) ?? [])].sort(), url, status, verdict });
});
links.sort((a, b) => a.url.localeCompare(b.url));

packages.sort((a, b) => `${a.skill}${a.name}`.localeCompare(`${b.skill}${b.name}`));

const bad = packages.filter((p) => p.verdict === "missing" || p.verdict === "abandoned");
const warn = packages.filter((p) => p.verdict === "stale" || p.verdict === "unknown");
// A link the host refused to serve us is not a link that is gone. Only 404 and
// 410 fail the run; everything else is reported and moves on.
const deadLinks = links.filter((l) => l.verdict === "dead");
const unreachableLinks = links.filter((l) => l.verdict === "unreachable");

if (asJson) {
  console.log(JSON.stringify({ packages, links }, null, 2));
} else {
  console.log(
    `verify-docs: ${packages.length} package claim(s), ${linkRefs.size} link(s), ${deadLinks.length} dead`,
  );
  const accepted = packages.filter((p) => p.verdict === "accepted");
  for (const p of [...bad, ...warn]) {
    const age = p.months === null || p.months === undefined ? "?" : `${p.months}mo`;
    console.log(
      `  ${p.verdict.toUpperCase().padEnd(9)} ${p.ecosystem}:${p.name} (${p.version ?? "-"}, ${age}) — ${p.skill}`,
    );
  }
  for (const l of [...deadLinks, ...unreachableLinks]) {
    const label = l.verdict === "dead" ? "DEAD" : "UNREACHED";
    console.log(
      `  ${label.padEnd(9)} ${l.status || "no response"}  ${l.url} — ${l.skills.join(", ")}`,
    );
  }
  if (accepted.length) {
    console.log(`  (${accepted.length} accepted as deliberately old)`);
  }
  const unknown = packages.filter((p) => p.verdict === "unknown").length;
  if (unknown || unreachableLinks.length) {
    const parts = [
      unknown ? `${unknown} package claim(s)` : "",
      unreachableLinks.length ? `${unreachableLinks.length} link(s)` : "",
    ].filter(Boolean);
    console.log(`  (${parts.join(" and ")} could not be reached — not counted as failures)`);
  }
  if (!bad.length && !deadLinks.length) {
    console.log(
      warn.length || unreachableLinks.length
        ? "no failures; re-read the entries above"
        : "all claims current",
    );
  }
}

process.exit(bad.length || deadLinks.length ? 1 : 0);
