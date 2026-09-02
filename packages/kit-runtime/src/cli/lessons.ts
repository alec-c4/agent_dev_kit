#!/usr/bin/env bun
/**
 * kit lessons — list / ack / propose / promote project and user-global lessons.
 *
 *   kit lessons list [--stack ID] [--project PATH]
 *   kit lessons ack L-n [--project PATH]
 *   kit lessons propose --fingerprint F --guide G --sensor S [--stack ID] [--source SRC]
 *   kit lessons promote L-n --global [--project PATH]
 */
import { resolve } from "node:path";
import {
  ackLesson,
  defaultGlobalLessonsPath,
  loadLessonsForSession,
  promoteLessonToGlobal,
  proposeLesson,
} from "../lessons.ts";

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

const argv = process.argv.slice(2);
const cmd = argv[0] ?? "list";
if (cmd === "-h" || cmd === "--help" || cmd === "help") {
  console.log(`Usage:
  kit lessons list [--stack ID] [--project PATH]
  kit lessons ack L-n [--project PATH]
  kit lessons propose --fingerprint F --guide G --sensor S [--stack ID] [--source SRC]
  kit lessons promote L-n --global [--project PATH]`);
  process.exit(0);
}

const rest = argv.slice(1);
const project = resolve(arg("--project", rest) ?? process.cwd());
const globalPath =
  arg("--global-path", rest) ?? defaultGlobalLessonsPath();

try {
  if (cmd === "list") {
    const stack = arg("--stack", rest) ?? "*";
    const rows = loadLessonsForSession(project, stack, globalPath);
    if (!rows.length) {
      console.log("(no lessons)");
      process.exit(0);
    }
    console.log(["ID", "STACK", "FINGERPRINT", "GUIDE"].join("\t"));
    for (const r of rows) {
      console.log([r.id, r.stack, r.fingerprint, r.guide].join("\t"));
    }
    process.exit(0);
  }

  if (cmd === "ack") {
    const id = rest.find((a) => /^L-\d+$/.test(a));
    if (!id) {
      console.error("ack requires L-n");
      process.exit(2);
    }
    const row = ackLesson(project, id);
    console.log(`${row.id}\t${row.ack}`);
    process.exit(0);
  }

  if (cmd === "propose") {
    const fingerprint = arg("--fingerprint", rest);
    const guide = arg("--guide", rest);
    const sensor = arg("--sensor", rest) ?? "check-patterns";
    if (!fingerprint || !guide) {
      console.error("propose requires --fingerprint and --guide");
      process.exit(2);
    }
    const row = proposeLesson(project, {
      fingerprint,
      stack: arg("--stack", rest) ?? "*",
      guide,
      sensor,
      source: arg("--source", rest) ?? "",
    });
    console.log(`${row.id}\t${row.ack}\t${row.occurrences}`);
    process.exit(0);
  }

  if (cmd === "promote") {
    const id = rest.find((a) => /^L-\d+$/.test(a));
    if (!id || !has("--global", rest)) {
      console.error("promote requires L-n and --global");
      process.exit(2);
    }
    const entry = promoteLessonToGlobal(project, id, globalPath);
    console.log(`${entry.fingerprint}\t${globalPath}`);
    process.exit(0);
  }

  console.error(`unknown lessons command: ${cmd}`);
  process.exit(2);
} catch (e) {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
}
