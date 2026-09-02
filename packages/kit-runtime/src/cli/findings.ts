#!/usr/bin/env bun
/**
 * kit findings — list / append / close / wontfix work findings.
 *
 *   kit findings list [work_ref] [--open] [--project PATH]
 *   kit findings append --work-ref R --fingerprint F --stage S --severity block|warn --summary T --evidence E
 *   kit findings close F-n --work-ref R --run "<sensor command>" | --from-sensor
 *   kit findings wontfix F-n --work-ref R --human
 *   kit findings gate --work-ref R [--remediation PATH]
 */
import { resolve } from "node:path";
import { readdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import { readFileSync } from "node:fs";
import {
  appendFinding,
  closeFinding,
  findingsGate,
  findingsPath,
  parseFindingsFile,
  wontfixFinding,
  type Finding,
} from "../findings.ts";

function arg(flag: string, argv: string[]): string | undefined {
  const i = argv.indexOf(flag);
  if (i >= 0) return argv[i + 1];
  const pref = `${flag}=`;
  const hit = argv.find((a) => a.startsWith(pref));
  return hit ? hit.slice(pref.length) : undefined;
}

function has(flag: string, argv: string[]): boolean {
  return argv.includes(flag);
}

function listWorkRefs(project: string): string[] {
  const dir = join(project, ".ai", "work");
  if (!existsSync(dir)) return [];
  const refs = new Set<string>();
  for (const f of readdirSync(dir)) {
    const m = f.match(/^(.+)-(analysis|plan|handoff|verification|findings)\.md$/);
    if (m) refs.add(m[1]);
  }
  return [...refs].sort();
}

function printRows(rows: Finding[]): void {
  if (!rows.length) {
    console.log("(no findings)");
    return;
  }
  console.log(
    ["ID", "STATUS", "SEV", "FINGERPRINT", "SUMMARY"].join("\t"),
  );
  for (const r of rows) {
    console.log(
      [r.id, r.status, r.severity, r.fingerprint, r.summary].join("\t"),
    );
  }
}

const argv = process.argv.slice(2);
const cmd = argv[0] ?? "list";
if (cmd === "-h" || cmd === "--help" || cmd === "help") {
  console.log(`Usage:
  kit findings list [work_ref] [--open] [--project PATH]
  kit findings append --work-ref R --fingerprint F --stage S --severity block|warn --summary T --evidence E
  kit findings close F-n --work-ref R --run "<sensor command>"   (verified)
  kit findings close F-n --work-ref R --from-sensor                (asserted)
  kit findings wontfix F-n --work-ref R --human
  kit findings gate --work-ref R [--remediation PATH]`);
  process.exit(0);
}

const rest = ["list", "append", "close", "wontfix", "gate"].includes(cmd)
  ? argv.slice(1)
  : argv;
const project = resolve(arg("--project", rest) ?? process.cwd());

try {
  if (cmd === "list") {
    const positional = rest.filter((a) => !a.startsWith("--") && a !== arg("--project", rest));
    const workRef = positional[0];
    const openOnly = has("--open", rest);
    const refs = workRef ? [workRef] : listWorkRefs(project);
    if (!refs.length) {
      console.log("(no work items)");
      process.exit(0);
    }
    for (const ref of refs) {
      let rows = parseFindingsFile(findingsPath(project, ref));
      if (openOnly) {
        rows = rows.filter((r) => r.status === "open" || r.status === "regressed");
      }
      if (refs.length > 1) console.log(`# ${ref}`);
      printRows(rows);
    }
    process.exit(0);
  }

  if (cmd === "append") {
    const workRef = arg("--work-ref", rest) ?? arg("--work_ref", rest);
    const fingerprint = arg("--fingerprint", rest);
    const stage = arg("--stage", rest) ?? "verify";
    const severity = (arg("--severity", rest) ?? "block") as "block" | "warn";
    const summary = arg("--summary", rest);
    const evidence = arg("--evidence", rest) ?? "";
    if (!workRef || !fingerprint || !summary) {
      console.error("append requires --work-ref, --fingerprint, --summary");
      process.exit(2);
    }
    const row = appendFinding(project, workRef, {
      fingerprint,
      stage,
      severity: severity === "warn" ? "warn" : "block",
      summary,
      evidence,
    });
    console.log(`${row.id}\t${row.status}\t${row.fingerprint}`);
    process.exit(0);
  }

  if (cmd === "close") {
    const id = rest.find((a) => /^F-\d+$/.test(a));
    const workRef = arg("--work-ref", rest);
    if (!id || !workRef) {
      console.error("close requires F-n and --work-ref");
      process.exit(2);
    }
    // --run makes the close verifiable: the sensor is executed here and the row
    // only closes on exit 0. --from-sensor stays as an unverified assertion.
    const sensorCmd = arg("--run", rest);
    let verifiedBy: { command: string; exitCode: number } | undefined;
    if (sensorCmd) {
      console.error(`running sensor: ${sensorCmd}`);
      const proc = Bun.spawnSync(["sh", "-c", sensorCmd], {
        cwd: project,
        stdout: "inherit",
        stderr: "inherit",
      });
      verifiedBy = { command: sensorCmd, exitCode: proc.exitCode ?? 1 };
    }
    const row = closeFinding(project, workRef, id, {
      fromSensor: has("--from-sensor", rest),
      verifiedBy,
    });
    console.log(`${row.id}\t${row.status}`);
    process.exit(0);
  }

  if (cmd === "wontfix") {
    const id = rest.find((a) => /^F-\d+$/.test(a));
    const workRef = arg("--work-ref", rest);
    if (!id || !workRef) {
      console.error("wontfix requires F-n and --work-ref");
      process.exit(2);
    }
    const row = wontfixFinding(project, workRef, id, {
      human: has("--human", rest),
    });
    console.log(`${row.id}\t${row.status}`);
    process.exit(0);
  }

  if (cmd === "gate") {
    const workRef = arg("--work-ref", rest) ?? arg("--work_ref", rest);
    if (!workRef) {
      console.error("gate requires --work-ref");
      process.exit(2);
    }
    const remediationPath = arg("--remediation", rest);
    let remediation: string | undefined;
    if (remediationPath) {
      try {
        remediation = readFileSync(remediationPath, "utf8");
      } catch {
        console.error(`cannot read remediation file: ${remediationPath}`);
        process.exit(2);
      }
    }
    const result = findingsGate(project, workRef, remediation);
    if (result.ok) {
      console.log(`findings gate: PASS (${workRef}) — no open block findings`);
      process.exit(0);
    }
    console.error(`findings gate: FAIL (${workRef})`);
    for (const row of result.blocking) {
      console.error(`  ${row.id}\t${row.status}\t${row.fingerprint}\t${row.summary}`);
    }
    if (result.missingFromRemediation.length) {
      console.error(
        `  not cited in ${remediationPath}: ${result.missingFromRemediation.join(", ")}`,
      );
    }
    process.exit(1);
  }

  console.error(`unknown findings command: ${cmd}`);
  process.exit(2);
} catch (e) {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
}
