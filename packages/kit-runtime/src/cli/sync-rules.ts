#!/usr/bin/env bun
/**
 * Scan Cursor user rules and build a dedup manifest for Agent Dev Kit.
 */
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  realpathSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { homedir } from "node:os";
import { findKitRoot } from "../detect-stack.ts";

type TopicConfig = {
  user_rule_patterns?: string[];
  skip_kit_guidelines?: string[];
};

type Registry = {
  kit_rule_prefix?: string;
  always_load?: string[];
  topics?: Record<string, TopicConfig>;
};

type LocalOverlay = {
  extra_topics?: Record<string, TopicConfig>;
  additional_skip?: string[];
};

type SkipEntry = {
  path: string;
  covered_by: string;
  topics: string[];
};

type DetectedRule = {
  file: string;
  path: string;
  topics: string[];
};

function expandUser(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function loadJson(path: string): Registry {
  return JSON.parse(readFileSync(path, "utf8")) as Registry;
}

function loadLocalOverlay(path: string): LocalOverlay {
  if (!existsSync(path)) return {};
  const parsed = Bun.YAML.parse(readFileSync(path, "utf8"));
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    return {};
  }
  return parsed as LocalOverlay;
}

export function mergeTopics(
  base: Record<string, TopicConfig>,
  overlay: LocalOverlay,
): Record<string, TopicConfig> {
  const merged: Record<string, TopicConfig> = {};
  for (const [k, v] of Object.entries(base)) {
    merged[k] = { ...v };
  }
  for (const [topic, cfg] of Object.entries(overlay.extra_topics ?? {})) {
    merged[topic] = {
      user_rule_patterns: [...(cfg.user_rule_patterns ?? [])],
      skip_kit_guidelines: [...(cfg.skip_kit_guidelines ?? [])],
    };
  }
  return merged;
}

export function matchRule(filename: string, patterns: string[]): string[] {
  const matched: string[] = [];
  for (const pattern of patterns) {
    if (new RegExp(pattern).test(filename)) matched.push(pattern);
  }
  return matched;
}

export function scanRules(rulesDir: string, kitPrefix: string): string[] {
  if (!existsSync(rulesDir)) return [];
  const files: string[] = [];
  for (const name of readdirSync(rulesDir).sort()) {
    if (!name.endsWith(".mdc")) continue;
    if (name.startsWith(kitPrefix)) continue;
    files.push(join(rulesDir, name));
  }
  return files;
}

/** Prefer linked install at ~/.cursor/agent_dev_kit; else walk from import.meta.dir. */
export function resolveKitRoot(startDir: string = import.meta.dir): string {
  const linked = join(homedir(), ".cursor", "agent_dev_kit");
  if (existsSync(linked)) {
    try {
      return realpathSync(linked);
    } catch {
      return resolve(linked);
    }
  }
  return findKitRoot(startDir);
}

export function buildManifest(
  registry: Registry,
  rulesDirs: string[],
  localOverlay: LocalOverlay,
  kitRoot: string,
): Record<string, unknown> {
  const kitPrefix = registry.kit_rule_prefix ?? "kit-";
  const alwaysLoad = [...(registry.always_load ?? [])];
  const topics = mergeTopics(registry.topics ?? {}, localOverlay);

  const detected: DetectedRule[] = [];
  const skipMap: Record<string, SkipEntry> = {};

  for (const rulesDir of rulesDirs) {
    for (const rulePath of scanRules(rulesDir, kitPrefix)) {
      const filename = rulePath.split("/").pop()!;
      const ruleTopics: string[] = [];
      for (const [topicId, cfg] of Object.entries(topics)) {
        const patterns = cfg.user_rule_patterns ?? [];
        const hits = matchRule(filename, patterns);
        if (!hits.length) continue;
        ruleTopics.push(topicId);
        for (const guideline of cfg.skip_kit_guidelines ?? []) {
          if (!(guideline in skipMap)) {
            skipMap[guideline] = {
              path: guideline,
              covered_by: filename,
              topics: [topicId],
            };
          } else {
            const entry = skipMap[guideline];
            if (!entry.topics.includes(topicId)) entry.topics.push(topicId);
            if (entry.covered_by !== filename) {
              entry.covered_by = `${entry.covered_by}, ${filename}`;
            }
          }
        }
      }

      if (ruleTopics.length) {
        detected.push({
          file: filename,
          path: rulePath,
          topics: [...new Set(ruleTopics)].sort(),
        });
      }
    }
  }

  for (const guideline of localOverlay.additional_skip ?? []) {
    if (!(guideline in skipMap)) {
      skipMap[guideline] = {
        path: guideline,
        covered_by: "kit-user-rules.local.yaml",
        topics: ["local_overlay"],
      };
    }
  }

  const skipList = Object.values(skipMap).sort((a, b) =>
    a.path.localeCompare(b.path),
  );
  const skipPaths = new Set(skipList.map((item) => item.path));
  const alwaysLoadResolved = alwaysLoad.map((rel) => resolve(kitRoot, rel));

  return {
    version: 1,
    generated_at: new Date().toISOString(),
    kit_root: resolve(kitRoot),
    rules_dirs: rulesDirs.filter((d) => existsSync(d)),
    kit_rule_prefix: kitPrefix,
    detected_user_rules: detected,
    skip_kit_guidelines: skipList,
    always_load_kit_guidelines: alwaysLoad,
    always_load_kit_guidelines_resolved: alwaysLoadResolved,
    optional_kit_guidelines: [
      "docs/guidelines/TESTING.md",
      "docs/guidelines/COMMITS.md",
      "docs/guidelines/GIT.md",
      "docs/guidelines/CODING.md",
    ].filter((path) => !skipPaths.has(path)),
    policy:
      "User ~/.cursor/rules win on conflict. " +
      "Do not read skip_kit_guidelines unless the human explicitly asks. " +
      "Always read always_load_kit_guidelines_resolved from kit_root — " +
      "paths are absolute under ~/.cursor/agent_dev_kit. " +
      "Global kit rules apply in every project; project install is optional.",
  };
}

function usage(): never {
  console.log(`Usage: kit-sync-rules [options]

Options:
  --registry PATH        Path to registry/cursor-user-rules.json
  --rules-dir PATH       Cursor rules directory (repeatable)
  --local-overlay PATH   Optional user overlay YAML
  --output PATH          Manifest output path
  --dry-run              Print manifest instead of writing
  -h, --help             Show help`);
  process.exit(0);
}

function main(): void {
  const args = process.argv.slice(2);
  let registryArg: string | null = null;
  const rulesDirArgs: string[] = [];
  let localOverlay = join(homedir(), ".cursor", "kit-user-rules.local.yaml");
  let output = join(homedir(), ".cursor", "kit-user-rules.manifest.json");
  let dryRun = false;

  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-h" || a === "--help") usage();
    else if (a === "--registry") registryArg = args[++i] ?? "";
    else if (a === "--rules-dir") rulesDirArgs.push(args[++i] ?? "");
    else if (a === "--local-overlay") localOverlay = args[++i] ?? localOverlay;
    else if (a === "--output") output = args[++i] ?? output;
    else if (a === "--dry-run") dryRun = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(1);
    }
  }

  const kitDir = findKitRoot(import.meta.dir);
  const registryPath =
    registryArg ?? join(kitDir, "registry", "cursor-user-rules.json");
  if (!existsSync(registryPath)) {
    console.error(
      `Missing ${registryPath}. Run: bash scripts/compile_registry.sh`,
    );
    process.exit(1);
  }

  let rulesDirs = rulesDirArgs.map((p) => expandUser(p));
  if (!rulesDirs.length) {
    rulesDirs = [join(homedir(), ".cursor", "rules")];
  }

  const registry = loadJson(registryPath);
  const overlay = loadLocalOverlay(expandUser(localOverlay));
  const kitRoot = resolveKitRoot(import.meta.dir);
  const manifest = buildManifest(registry, rulesDirs, overlay, kitRoot);

  const payload = JSON.stringify(manifest, null, 2) + "\n";
  if (dryRun) {
    process.stdout.write(payload);
    return;
  }

  const out = expandUser(output);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, payload, "utf8");
  console.log(`wrote ${out}`);
  const detected = manifest.detected_user_rules as unknown[];
  const skip = manifest.skip_kit_guidelines as unknown[];
  console.log(
    `  user rules: ${detected.length}, skip kit guidelines: ${skip.length}`,
  );
}

try {
  main();
} catch (e) {
  console.error(e instanceof Error ? e.message : String(e));
  process.exit(1);
}
