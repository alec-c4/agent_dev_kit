#!/usr/bin/env bun
/**
 * kit check-patterns — scan shipped paths against registry/failure-patterns.yaml
 *
 *   kit check-patterns [--work-ref R] [--project PATH] [--catalog PATH]
 */
import { existsSync, readFileSync } from "node:fs";
import { resolve, join } from "node:path";
import { checkPatterns, loadSensorCatalog } from "../patterns.ts";
import { loadKitProjectConfig } from "../kit-config.ts";

function arg(flag: string, argv: string[]): string | undefined {
  const i = argv.indexOf(flag);
  if (i >= 0) return argv[i + 1];
  const pref = `${flag}=`;
  const hit = argv.find((a) => a.startsWith(pref));
  return hit ? hit.slice(pref.length) : undefined;
}

const argv = process.argv.slice(2);
if (argv.includes("-h") || argv.includes("--help")) {
  console.log(
    "Usage: kit check-patterns [--work-ref R] [--project PATH] [--catalog PATH] [--stack ID] [--list-sensors]",
  );
  process.exit(0);
}

const project = resolve(arg("--project", argv) ?? process.cwd());
const workRef = arg("--work-ref", argv);
const kitRoot = join(import.meta.dir, "..", "..", "..", "..");
const catalog =
  arg("--catalog", argv) ?? join(kitRoot, "registry", "failure-patterns.yaml");
const kit = loadKitProjectConfig(project);
if (kit.error) console.error(`warning: ${kit.error}`);

/**
 * Stack-scoped catalog rows need to know the project's stack. `kit detect-stack
 * --write-profile` leaves it on disk; --stack overrides. With neither, only the
 * `*` rows run.
 */
function detectedStack(): string | undefined {
  const explicit = arg("--stack", argv);
  if (explicit) return explicit;
  const profile = join(project, ".claude", "stack.profile.json");
  if (!existsSync(profile)) return undefined;
  try {
    const parsed = JSON.parse(readFileSync(profile, "utf8")) as {
      primary_stack?: string;
    };
    return parsed.primary_stack || undefined;
  } catch {
    return undefined;
  }
}

const sensors = loadSensorCatalog(catalog);
if (argv.includes("--list-sensors")) {
  if (!sensors.length) {
    console.log("(no sensor-owned fingerprints in catalog)");
    process.exit(0);
  }
  console.log("FINGERPRINT\tSENSOR\tGUIDE");
  for (const s of sensors) {
    console.log(`${s.fingerprint}\t${s.sensor ?? "-"}\t${s.guide}`);
  }
  process.exit(0);
}

const result = checkPatterns(project, {
  catalogPath: catalog,
  enabled: kit.config.pattern_checks,
  workRef,
  stack: detectedStack(),
});

if (result.skipped) {
  console.log("check-patterns skipped (pattern_checks: false)");
  process.exit(0);
}

function printSensorReminder(): void {
  if (!sensors.length) return;
  console.error(
    `check-patterns cannot see ${sensors.length} sensor-owned fingerprint(s); the verifier must assert them (--list-sensors for the guidance):`,
  );
  for (const s of sensors) {
    console.error(`  ${s.fingerprint} — sensor: ${s.sensor ?? "-"}`);
  }
}

function printHits(): void {
  for (const h of result.hits) {
    const line = `  ${h.severity.toUpperCase()} ${h.path}: ${h.fingerprint} (${h.token})`;
    if (h.severity === "block") console.error(line);
    else console.log(line);
  }
}

if (result.ok) {
  if (result.hits.length) {
    console.log(`check-patterns: ${result.hits.length} warning(s), nothing blocking`);
    printHits();
  } else {
    console.log("check-patterns: no hits");
  }
  printSensorReminder();
  process.exit(0);
}

console.error("check-patterns: hits");
printHits();
printSensorReminder();
process.exit(1);
