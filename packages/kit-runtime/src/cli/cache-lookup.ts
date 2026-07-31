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
const data = JSON.parse(readFileSync(cachePath, "utf8")) as {
  items?: Array<{ work_ref?: string; title?: string; url?: string; status?: string }>;
};
const item = (data.items || []).find((i) => i.work_ref === workRef);
console.log(item?.title || "");
console.log(item?.url || "");
console.log(item?.status || "");
