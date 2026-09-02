import {
  existsSync,
  mkdirSync,
  openSync,
  closeSync,
  readFileSync,
  renameSync,
  statSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { kitConfigPath } from "./kit-paths.ts";

export type ProjectEntry = {
  id: string;
  path: string;
  added_at: string;
  last_seen_at: string;
};

export type ProjectsFile = {
  version: 1;
  projects: ProjectEntry[];
};

export function defaultProjectsPath(): string {
  return kitConfigPath("projects.yaml");
}

function nowIso(): string {
  return new Date().toISOString();
}

/** No kit command holds the registry lock for longer than this. */
const STALE_LOCK_MS = 30_000;

function lockAgeMs(lockPath: string): number {
  try {
    return Date.now() - statSync(lockPath).mtimeMs;
  } catch {
    return 0;
  }
}

function slugFromPath(path: string): string {
  const base = path.replace(/\/+$/, "").split("/").pop() || "project";
  return base.replace(/[^a-zA-Z0-9._-]+/g, "-").toLowerCase();
}

/** Quote YAML scalars that need it (paths, times with `:`). */
function yamlScalar(value: string | number): string {
  const s = String(value);
  if (/^[\w./@+-]+$/.test(s) && !s.includes(":")) return s;
  return JSON.stringify(s);
}

/** Block-style YAML — Bun.YAML.stringify emits JSON-like flow style. */
export function formatProjectsYaml(data: ProjectsFile): string {
  const lines = [`version: ${data.version}`, "projects:"];
  if (!data.projects.length) {
    lines.push("  []");
  } else {
    for (const p of data.projects) {
      lines.push(`  - id: ${yamlScalar(p.id)}`);
      lines.push(`    path: ${yamlScalar(p.path)}`);
      lines.push(`    added_at: ${yamlScalar(p.added_at)}`);
      lines.push(`    last_seen_at: ${yamlScalar(p.last_seen_at)}`);
    }
  }
  return lines.join("\n") + "\n";
}

export function loadProjects(filePath: string): ProjectsFile {
  if (!existsSync(filePath)) {
    return { version: 1, projects: [] };
  }
  const raw = readFileSync(filePath, "utf8");
  const parsed = Bun.YAML.parse(raw) as ProjectsFile | null;
  if (!parsed || parsed.version !== 1 || !Array.isArray(parsed.projects)) {
    return { version: 1, projects: [] };
  }
  return parsed;
}

/**
 * Drop entries whose project directory was deleted.
 *
 * An unreachable path is not proof of deletion: an unmounted volume or a
 * disconnected network share makes every project under it vanish, and pruning
 * them would quietly lose the registry. Only prune when the parent directory
 * is still there, which means the mount is up and the project itself is gone.
 */
export function pruneProjects(data: ProjectsFile): ProjectsFile {
  return {
    version: 1,
    projects: data.projects.filter((p) => {
      if (existsSync(p.path)) return true;
      const parent = dirname(p.path);
      return parent === p.path || !existsSync(parent);
    }),
  };
}

/**
 * Atomic write with exclusive flock via O_EXCL lockfile.
 * Pattern: write temp → rename; lock via sibling `.lock` using open O_EXCL retry.
 */
export function saveProjects(filePath: string, data: ProjectsFile): void {
  const dir = dirname(filePath);
  mkdirSync(dir, { recursive: true });
  const lockPath = `${filePath}.lock`;
  const tmpPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;

  let lockFd: number | null = null;
  const started = Date.now();
  while (lockFd === null) {
    try {
      lockFd = openSync(lockPath, "wx");
    } catch {
      // A crash between open and unlink leaves the lock behind and would wedge
      // every later write. Break a lock that no live writer could still hold.
      if (lockAgeMs(lockPath) > STALE_LOCK_MS) {
        try {
          unlinkSync(lockPath);
          continue;
        } catch {
          /* another writer won the race — fall through and keep waiting */
        }
      }
      if (Date.now() - started > 5000) {
        throw new Error(
          `Timeout acquiring lock ${lockPath} — remove it if no kit command is running`,
        );
      }
      Bun.sleepSync(20);
    }
  }

  try {
    const pruned = pruneProjects(data);
    writeFileSync(tmpPath, formatProjectsYaml(pruned), "utf8");
    renameSync(tmpPath, filePath);
  } finally {
    try {
      closeSync(lockFd);
    } catch {
      /* ignore */
    }
    try {
      unlinkSync(lockPath);
    } catch {
      /* ignore */
    }
    try {
      unlinkSync(tmpPath);
    } catch {
      /* ignore */
    }
  }
}

export function upsertProject(
  filePath: string,
  projectPath: string,
  id?: string,
): ProjectEntry {
  const abs = resolve(projectPath);
  const now = nowIso();
  const entry: ProjectEntry = {
    id: id || slugFromPath(abs),
    path: abs,
    added_at: now,
    last_seen_at: now,
  };
  try {
    const data = pruneProjects(loadProjects(filePath));
    const existing = data.projects.find((p) => p.path === abs);
    if (existing) {
      existing.last_seen_at = now;
      saveProjects(filePath, data);
      return existing;
    }
    data.projects.push(entry);
    saveProjects(filePath, data);
    return entry;
  } catch (e) {
    console.error(`warning: could not update projects registry (${filePath}): ${e}`);
    return entry;
  }
}
