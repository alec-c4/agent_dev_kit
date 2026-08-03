#!/usr/bin/env bun
/**
 * Parse SKILL.md YAML frontmatter; print name, ---SPLIT---, description.
 * Used by validate-skills.sh (Bun primary; ruby fallback in shell).
 */
import { readFileSync } from "node:fs";

const skillMd = process.argv[2];
if (!skillMd) {
  console.log("MISSING");
  process.exit(0);
}

const text = readFileSync(skillMd, "utf8");
const m = text.match(/^---\s*\n([\s\S]*?)\n---/);
if (!m) {
  console.log("MISSING");
  process.exit(0);
}

try {
  const data = Bun.YAML.parse(m[1]) as { name?: string; description?: string } | null;
  if (!data || typeof data !== "object") {
    console.log("INVALID");
    process.exit(0);
  }
  console.log(data.name ?? "");
  console.log("---SPLIT---");
  console.log(data.description ?? "");
} catch {
  console.log("INVALID");
}
