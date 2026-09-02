#!/usr/bin/env bun
/**
 * kit check-patterns — scan shipped paths against registry/failure-patterns.yaml
 *
 *   kit check-patterns [--work-ref R] [--project PATH] [--catalog PATH]
 */
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
    "Usage: kit check-patterns [--work-ref R] [--project PATH] [--catalog PATH] [--list-sensors]",
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
});

if (result.skipped) {
  console.log("check-patterns skipped (pattern_checks: false)");
  process.exit(0);
}

function printSensorReminder(): void {
  if (!sensors.length) return;
  console.error(
    `check-patterns cannot see ${sensors.length} sensor-owned fingerprint(s); the verifier must assert them:`,
  );
  for (const s of sensors) {
    console.error(`  ${s.fingerprint} (sensor: ${s.sensor ?? "-"}) — ${s.guide}`);
  }
}

if (result.ok) {
  console.log("check-patterns: no hits");
  printSensorReminder();
  process.exit(0);
}

console.error("check-patterns: hits");
for (const h of result.hits) {
  console.error(`  ${h.path}: ${h.fingerprint} (${h.token})`);
}
printSensorReminder();
process.exit(1);
