#!/usr/bin/env bun
/** Look up title/url/status from tracker-cache.json by work_ref. */
import { existsSync, readFileSync } from "node:fs";

const [cachePath, workRef] = process.argv.slice(2);
if (!cachePath || !workRef) {
  console.log("\n\n");
  process.exit(0);
}
if (!existsSync(cachePath)) {
  console.log("\n\n");
  process.exit(0);
}
// A hand-edited or truncated cache must not crash intake — it is only a hint.
let data: {
  items?: Array<{ work_ref?: string; title?: string; url?: string; status?: string }>;
} = {};
try {
  data = JSON.parse(readFileSync(cachePath, "utf8"));
} catch {
  console.log("\n\n");
  process.exit(0);
}
const item = (data.items || []).find((i) => i.work_ref === workRef);
console.log(item?.title || "");
console.log(item?.url || "");
console.log(item?.status || "");
