#!/usr/bin/env bun
/**
 * Structural checks on comprehension handoff markdown.
 * Usage: bun validate-handoff.ts <handoffPath> [tier]
 */
import { readFileSync } from "node:fs";

const path = process.argv[2];
const tierOverride = (process.argv[3] || "").trim().toLowerCase();
if (!path) {
  console.error("Usage: validate-handoff.ts <path> [tier]");
  process.exit(1);
}

const text = readFileSync(path, "utf8");
const errors: string[] = [];

function require(pattern: RegExp, msg: string): void {
  if (!pattern.test(text)) errors.push(msg);
}

require(/^#\s+Handoff:/m, "missing H1 Handoff title");
require(/\*\*Comprehension tier:\*\*/i, "missing Comprehension tier field");

const tierMatch = text.match(/\*\*Comprehension tier:\*\*\s*(\w+)/i);
let tier = (tierOverride || (tierMatch?.[1] ?? "standard")).toLowerCase();

if (!["minimal", "standard", "strict"].includes(tier)) {
  errors.push(`unknown comprehension tier: ${tier}`);
}

if (tier === "minimal") {
  console.log(`OK: minimal tier — structural gate skipped (${path})`);
  process.exit(0);
}

require(/## What changed/i, "missing ## What changed");
require(/## Data flow/i, "missing ## Data flow");
require(/## Key files/i, "missing ## Key files");
require(/## Comprehension Q&A/i, "missing ## Comprehension Q&A");
require(/## Human sign-off/i, "missing ## Human sign-off");

const qaBlocks = (text.match(/^### Q\d+/gm) || []).length;
const expectedQa = tier === "strict" ? 5 : 3;
if (qaBlocks < expectedQa) {
  errors.push(`expected at least ${expectedQa} Q&A blocks (### Qn), found ${qaBlocks}`);
}

if (!/\*\*Signed:\*\*\s*\S/.test(text)) {
  errors.push("missing Human sign-off Signed date");
}

if (tier === "strict") {
  require(/\*\*Teach-back:\*\*/i, "strict tier requires Teach-back in Human sign-off");
}

if (errors.length) {
  console.error(`FAIL: ${path}`);
  for (const e of errors) console.error(`  - ${e}`);
  process.exit(1);
}

console.log(`OK: handoff structure valid (${tier}, ${qaBlocks} Q&A, ${path})`);
