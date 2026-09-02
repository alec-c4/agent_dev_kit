import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

export type TrackerConfig = {
  provider: string;
  work_filename: string;
  cache_file: string;
  work_ref_format?: string;
  cache_max_items?: number;
  cache_statuses?: string[];
  [key: string]: unknown;
};

const DEFAULTS: TrackerConfig = {
  provider: "none",
  work_filename: "work/{work_ref}-{kind}.md",
  cache_file: "tracker-cache.json",
  work_ref_format: "GH-{n}",
  cache_max_items: 50,
  cache_statuses: ["open"],
};

export function loadTrackerConfig(projectDir: string): TrackerConfig {
  const path = join(projectDir, ".ai", "tracker.yaml");
  if (!existsSync(path)) {
    return { ...DEFAULTS };
  }
  try {
    const data = (Bun.YAML.parse(readFileSync(path, "utf8")) || {}) as Record<
      string,
      unknown
    >;
    return {
      ...DEFAULTS,
      ...data,
      provider: String(data.provider ?? DEFAULTS.provider),
      work_filename: String(data.work_filename ?? DEFAULTS.work_filename),
      cache_file: String(data.cache_file ?? DEFAULTS.cache_file),
    };
  } catch {
    return { ...DEFAULTS };
  }
}

/** `..` and absolute paths would escape `.ai/` — keep artifacts inside it. */
function safeSegment(value: string): string {
  return value.replace(/[/\\]/g, "-").replace(/\.\./g, "-");
}

export function workArtifactPath(
  projectDir: string,
  workRef: string,
  kind: string,
): string {
  const cfg = loadTrackerConfig(projectDir);
  const rel = cfg.work_filename
    .replaceAll("{work_ref}", safeSegment(workRef))
    .replaceAll("{kind}", safeSegment(kind));
  return join(".ai", rel);
}

export function cacheFilePath(projectDir: string): string {
  const cfg = loadTrackerConfig(projectDir);
  const rel = cfg.cache_file.startsWith(".ai/")
    ? cfg.cache_file
    : join(".ai", cfg.cache_file);
  return rel;
}
