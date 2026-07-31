#!/usr/bin/env bun
/**
 * Compile registry YAML → pretty JSON (Bun primary path for kit compile).
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { findKitRoot } from "../detect-stack.ts";

const KIT = findKitRoot(import.meta.dir);

function loadYaml(path: string): unknown {
  return Bun.YAML.parse(readFileSync(path, "utf8"));
}

function writeJson(path: string, data: unknown): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(data, null, 2) + "\n", "utf8");
  console.log(`wrote ${path}`);
}

function compileOne(dir: string, name: string): void {
  const yaml = join(dir, `${name}.yaml`);
  const json = join(dir, `${name}.json`);
  if (!existsSync(yaml)) return;
  writeJson(json, loadYaml(yaml));
}

const reg = join(KIT, "registry");
for (const name of [
  "stacks",
  "topics",
  "dod",
  "gates",
  "cursor-user-rules",
  "tool-targets",
  "tool-settings",
  "locales",
]) {
  compileOne(reg, name);
}

const stacksDir = join(KIT, "skills", "stacks");
if (existsSync(stacksDir)) {
  for (const id of readdirSync(stacksDir)) {
    const yaml = join(stacksDir, id, "profile.yaml");
    if (!existsSync(yaml)) continue;
    writeJson(join(stacksDir, id, "profile.json"), loadYaml(yaml));
  }
}

function compileManifests(globDir: string): void {
  if (!existsSync(globDir)) return;
  for (const entry of readdirSync(globDir)) {
    if (entry === "_template" || entry.startsWith(".")) continue;
    const yaml = join(globDir, entry, "manifest.yaml");
    if (!existsSync(yaml)) continue;
    writeJson(join(globDir, entry, "manifest.json"), loadYaml(yaml));
  }
}

compileManifests(join(KIT, "packs"));
compileManifests(join(KIT, "packs", "community"));
