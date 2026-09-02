import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Glob } from "bun";

function globFiles(pattern: string, cwd: string): string[] {
  return [...new Glob(pattern).scanSync({ cwd, onlyFiles: true })];
}

export type Json = null | boolean | number | string | Json[] | { [k: string]: Json };

function readText(path: string): string {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

function loadData(kit: string, name: string): Record<string, unknown> {
  const jsonPath = join(kit, "registry", `${name}.json`);
  const yamlPath = join(kit, "registry", `${name}.yaml`);
  if (existsSync(jsonPath)) {
    return JSON.parse(readFileSync(jsonPath, "utf8")) as Record<string, unknown>;
  }
  if (existsSync(yamlPath)) {
    const parsed = Bun.YAML.parse(readFileSync(yamlPath, "utf8"));
    return (parsed ?? {}) as Record<string, unknown>;
  }
  throw new Error(`No registry/${name}.json or .yaml in ${kit}`);
}

function loadYamlPath(path: string): Record<string, unknown> {
  if (path.endsWith(".json")) {
    return JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
  }
  const parsed = Bun.YAML.parse(readFileSync(path, "utf8"));
  return (parsed ?? {}) as Record<string, unknown>;
}

function loadStackProfile(kit: string, stackSkill: string): Record<string, unknown> {
  const base = join(kit, "skills", stackSkill);
  const jsonPath = join(base, "profile.json");
  const yamlPath = join(base, "profile.yaml");
  if (existsSync(jsonPath)) {
    return JSON.parse(readFileSync(jsonPath, "utf8")) as Record<string, unknown>;
  }
  if (existsSync(yamlPath)) {
    return loadYamlPath(yamlPath);
  }
  throw new Error(`Missing stack profile: ${yamlPath}`);
}

function resolveDodChecklist(
  profile: Record<string, unknown>,
  dod: Record<string, unknown>,
): unknown[] {
  const items = [...((dod.universal as unknown[]) || [])];
  items.push(...((profile.dod_overlay as unknown[]) || []));
  return items;
}

function packageDeps(cwd: string): Record<string, string> {
  const pkg = join(cwd, "package.json");
  if (!existsSync(pkg)) return {};
  try {
    const data = JSON.parse(readText(pkg)) as {
      dependencies?: Record<string, string>;
      devDependencies?: Record<string, string>;
    };
    return { ...(data.dependencies || {}), ...(data.devDependencies || {}) };
  } catch {
    return {};
  }
}

function gemfileHasGem(gemfile: string, gemName: string): boolean {
  const escaped = gemName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\\ /g, "[\\s_\\-]*");
  const re1 = new RegExp(`gem\\s+['"]${escaped}['"]`, "i");
  const alt = gemName.replace(/_/g, "-");
  const re2 = new RegExp(`gem\\s+['"]${alt}['"]`, "i");
  return re1.test(gemfile) || re2.test(gemfile);
}

function matchesStack(
  stackId: string,
  spec: Record<string, unknown>,
  cwd: string,
  stacks: Record<string, Record<string, unknown>>,
): boolean {
  const detect = (spec.detect as Record<string, unknown>) || {};
  const files = (detect.files as string[]) || [];
  const anyFiles = (detect.any_files as string[]) || [];
  const anyGlob = (detect.any_glob as string[]) || [];

  if (files.length && !files.every((f) => existsSync(join(cwd, f)))) {
    return false;
  }

  if (anyFiles.length || anyGlob.length) {
    let matched = anyFiles.some((f) => existsSync(join(cwd, f)));
    if (anyGlob.length) {
      matched =
        matched ||
        anyGlob.some((g) => globFiles(g, cwd).length > 0);
    }
    if (!files.length && !matched) return false;
  }

  const dep = detect.package_dep as string | undefined;
  if (dep && !(dep in packageDeps(cwd))) return false;

  const exclude = detect.exclude_package_dep as string | undefined;
  if (exclude && exclude in packageDeps(cwd)) return false;

  const match = detect.content_match as string | undefined;
  if (match) {
    let combined = "";
    for (const name of files) combined += readText(join(cwd, name)) + "\n";
    if (!files.length) {
      for (const name of anyFiles) {
        const p = join(cwd, name);
        if (existsSync(p)) combined += readText(p) + "\n";
      }
      for (const pattern of anyGlob) {
        for (const p of globFiles(pattern, cwd)) {
          combined += readText(join(cwd, p)) + "\n";
        }
      }
    }
    const manage = join(cwd, "manage.py");
    if (existsSync(manage)) combined += readText(manage);
    if (!combined.toLowerCase().includes(match.toLowerCase())) return false;
  }

  const gem = detect.gem as string | undefined;
  if (gem) {
    const gemfile = readText(join(cwd, "Gemfile"));
    if (!gemfileHasGem(gemfile, gem)) return false;
  }

  if (stackId === "python") {
    for (const other of ["fastapi", "django", "flask"]) {
      const otherSpec = stacks[other];
      if (otherSpec && matchesStack(other, otherSpec, cwd, stacks)) return false;
    }
  }

  if (stackId === "node") {
    for (const other of ["nextjs", "nuxt", "sveltekit", "svelte", "astro", "react-native"]) {
      const otherSpec = stacks[other];
      if (otherSpec && matchesStack(other, otherSpec, cwd, stacks)) return false;
    }
  }

  return true;
}

function resolveSkills(profile: Record<string, unknown>, cwd: string): string[] {
  const skillsCfg = (profile.skills as Record<string, unknown>) || {};
  const out: string[] = [];
  const seen = new Set<string>();
  const add = (name: string) => {
    if (name && !seen.has(name)) {
      seen.add(name);
      out.push(name);
    }
  };

  const stackSkill = profile.stack_skill as string | undefined;
  if (stackSkill) add(stackSkill);

  for (const key of ["required", "recommended"] as const) {
    for (const s of (skillsCfg[key] as string[]) || []) add(s);
  }

  // Not exclusive: a Rails app can carry both spec/ and test/, and the
  // matching skill describes itself as loading whenever its directory exists.
  if (existsSync(join(cwd, "spec"))) {
    for (const s of (skillsCfg.if_spec_dir as string[]) || []) add(s);
  }
  if (existsSync(join(cwd, "test"))) {
    for (const s of (skillsCfg.if_test_dir as string[]) || []) add(s);
  }

  const gemfile = readText(join(cwd, "Gemfile"));
  for (const [gem, skillList] of Object.entries(
    (skillsCfg.if_gem as Record<string, string[]>) || {},
  )) {
    if (gemfileHasGem(gemfile, gem)) {
      for (const s of skillList) add(s);
    }
  }

  const deps = packageDeps(cwd);
  for (const [depName, skillList] of Object.entries(
    (skillsCfg.if_package_dep as Record<string, string[]>) || {},
  )) {
    if (depName in deps) {
      for (const s of skillList) add(s);
    }
  }

  for (const [rel, rule] of Object.entries(
    (skillsCfg.if_file as Record<string, { content_match?: string; skills?: string[] }>) ||
      {},
  )) {
    const path = join(cwd, rel);
    if (!existsSync(path)) continue;
    if (rule.content_match && !readText(path).toLowerCase().includes(rule.content_match.toLowerCase())) {
      continue;
    }
    for (const s of rule.skills || []) add(s);
  }

  return out;
}

function resolveTopicFiles(
  primary: string,
  topics: Record<string, unknown>,
): Record<string, string> {
  const result: Record<string, string> = {};
  const topicMap = (topics.topics as Record<string, { stack_files?: Record<string, string> }>) || {};
  for (const [topicId, cfg] of Object.entries(topicMap)) {
    const rel = cfg.stack_files?.[primary];
    if (rel) result[topicId] = `skills/${rel}`;
  }
  return result;
}

export function detect(cwdIn: string, kitIn: string): Record<string, unknown> {
  const cwd = resolve(cwdIn);
  const kit = resolve(kitIn);
  const registry = loadData(kit, "stacks");
  const topics = loadData(kit, "topics");
  let dod: Record<string, unknown> = { universal: [] };
  try {
    dod = loadData(kit, "dod");
  } catch {
    /* empty */
  }

  const order = (registry.detection_order as string[]) || [];
  const stacks = (registry.stacks as Record<string, Record<string, unknown>>) || {};

  let primary: string | null = null;
  let stackEntry: Record<string, unknown> | null = null;
  for (const stackId of order) {
    const spec = stacks[stackId];
    if (spec && matchesStack(stackId, spec, cwd, stacks)) {
      primary = stackId;
      stackEntry = spec;
      break;
    }
  }

  const now = new Date().toISOString();

  if (!primary || !stackEntry) {
    return {
      version: 1,
      detected_at: now,
      cwd,
      primary_stack: null,
      error:
        "No stack matched. Declare stack in project CLAUDE.md or add detection in registry/stacks.yaml",
    };
  }

  const stackSkill = stackEntry.stack_skill as string | undefined;
  if (!stackSkill) {
    return {
      version: 1,
      detected_at: now,
      cwd,
      primary_stack: primary,
      error: `Stack ${primary} missing stack_skill in registry/stacks.yaml`,
    };
  }

  let profile: Record<string, unknown>;
  try {
    profile = { ...loadStackProfile(kit, stackSkill), stack_skill: stackSkill };
  } catch (e) {
    return {
      version: 1,
      detected_at: now,
      cwd,
      primary_stack: primary,
      error: String(e instanceof Error ? e.message : e),
    };
  }

  const tooling = { ...((profile.tooling as Record<string, unknown>) || {}) };

  return {
    version: 1,
    detected_at: now,
    cwd,
    primary_stack: primary,
    stack_skill: stackSkill,
    label: profile.label,
    language: profile.language,
    framework: profile.framework,
    tooling,
    universal_tooling: registry.universal_tooling || {},
    skills_to_load: resolveSkills(profile, cwd),
    topic_files: resolveTopicFiles(primary, topics),
    mcp_suggest: profile.mcp_suggest || [],
    dod_checklist: resolveDodChecklist(profile, dod),
    stack_profile_path: resolve(join(kit, "skills", stackSkill, "profile.yaml")),
    dod_registry_path: resolve(join(kit, "registry", "dod.yaml")),
  };
}

/**
 * Cache location for the detected profile. Defaults to `.claude/` because that
 * is what every kit doc and skill reads; `KIT_STACK_PROFILE_DIR` redirects it
 * for projects that do not want a Claude-named directory.
 */
export function stackProfileDir(cwd: string): string {
  const override = process.env.KIT_STACK_PROFILE_DIR;
  if (override) {
    return override.startsWith("/") ? override : join(cwd, override);
  }
  return join(cwd, ".claude");
}

export function writeProfile(cwd: string, profile: Record<string, unknown>): string {
  const outDir = stackProfileDir(cwd);
  mkdirSync(outDir, { recursive: true });
  const outPath = join(outDir, "stack.profile.json");
  writeFileSync(outPath, JSON.stringify(profile, null, 2) + "\n", "utf8");
  return outPath;
}

export function findKitRoot(startDir: string): string {
  let dir = resolve(startDir);
  for (let i = 0; i < 8; i++) {
    if (
      existsSync(join(dir, "registry", "stacks.json")) ||
      existsSync(join(dir, "registry", "stacks.yaml"))
    ) {
      return dir;
    }
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error(`Could not find kit root (registry/) from ${startDir}`);
}

export function kitDirFromImportMeta(metaUrl: string): string {
  return findKitRoot(dirname(fileURLToPath(metaUrl)));
}
