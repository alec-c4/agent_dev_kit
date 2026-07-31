#!/usr/bin/env bun
/**
 * Resolve work artifact relative path from tracker.yaml.
 * Usage: bun .../work-path.ts <projectDir> <workRef> <kind>
 * Prints: relative path\nprovider
 */
import { workArtifactPath, loadTrackerConfig } from "../tracker-config.ts";

const [projectDir, workRef, kind] = process.argv.slice(2);
if (!projectDir || !workRef || !kind) {
  console.error("Usage: work-path.ts <projectDir> <workRef> <kind>");
  process.exit(1);
}
console.log(workArtifactPath(projectDir, workRef, kind));
console.log(loadTrackerConfig(projectDir).provider);
