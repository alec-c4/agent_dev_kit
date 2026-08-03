#!/usr/bin/env bun
import { resolve } from "node:path";
import { detect, kitDirFromImportMeta, writeProfile } from "../detect-stack.ts";

const args = process.argv.slice(2);
let cwd = ".";
let write = false;
let kitDir: string | undefined;

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "--write-profile") write = true;
  else if (a === "--cwd") cwd = args[++i] ?? ".";
  else if (a === "--kit-dir") kitDir = args[++i];
  else if (a === "-h" || a === "--help") {
    console.log("Usage: kit-detect-stack [--write-profile] [--cwd DIR] [--kit-dir DIR]");
    process.exit(0);
  } else if (!a.startsWith("--")) {
    cwd = a;
  }
}

const kit = kitDir ? resolve(kitDir) : kitDirFromImportMeta(import.meta.url);
const stacksJson = `${kit}/registry/stacks.json`;
const stacksYaml = `${kit}/registry/stacks.yaml`;
const { existsSync } = await import("node:fs");
if (!existsSync(stacksJson) && !existsSync(stacksYaml)) {
  console.log(JSON.stringify({ error: `Registry not found in ${kit}/registry` }));
  process.exit(1);
}

const profile = detect(cwd, kit);
console.log(JSON.stringify(profile, null, 2));

if (write && profile.primary_stack) {
  const out = writeProfile(resolve(cwd), profile);
  console.error(`Wrote ${out}`);
}

process.exit(profile.primary_stack ? 0 : 1);
