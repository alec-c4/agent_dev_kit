#!/usr/bin/env bun
/**
 * Apply Agent Dev Kit settings to Cursor and Claude Code tool configs.
 */
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";
import { findKitRoot } from "../detect-stack.ts";
import {
  applyClaudeSettings,
  applyCursorSettings,
  resolveAttributionFlags,
  type JsonObject,
} from "../tool-settings.ts";

function expandUser(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function kitConfigDir(): string {
  const xdg = process.env.XDG_CONFIG_HOME;
  if (xdg) return join(expandUser(xdg), "agent_dev_kit");
  return join(homedir(), ".config", "agent_dev_kit");
}

function defaultKitConfigPath(): string {
  return join(kitConfigDir(), "config.yaml");
}

function resolveKitConfigPath(explicit: string | null): string {
  if (explicit !== null) return expandUser(explicit);
  return defaultKitConfigPath();
}

function loadYaml(path: string): JsonObject {
  if (!existsSync(path)) return {};
  const parsed = Bun.YAML.parse(readFileSync(path, "utf8"));
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    return {};
  }
  return parsed as JsonObject;
}

function loadRegistryDefaults(kitDir: string): JsonObject {
  const jsonPath = join(kitDir, "registry", "tool-settings.json");
  const yamlPath = join(kitDir, "registry", "tool-settings.yaml");
  if (existsSync(jsonPath)) {
    return JSON.parse(readFileSync(jsonPath, "utf8")) as JsonObject;
  }
  if (existsSync(yamlPath)) {
    return loadYaml(yamlPath);
  }
  return {};
}

function parseBool(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) return true;
  if (["0", "false", "no", "off"].includes(normalized)) return false;
  throw new Error(`expected boolean, got: ${value}`);
}

function configExamplePath(kitDir: string): string {
  return join(kitDir, "templates", "config", "config.yaml.example");
}

function initConfigFromExample(
  configPath: string,
  kitDir: string,
  dryRun: boolean,
): void {
  const example = configExamplePath(kitDir);
  if (!existsSync(example)) {
    console.error(`Missing template: ${example}`);
    process.exit(1);
  }
  if (existsSync(configPath)) return;
  if (dryRun) {
    console.log(`[dry-run] would copy ${example} -> ${configPath}`);
    return;
  }
  mkdirSync(dirname(configPath), { recursive: true });
  copyFileSync(example, configPath);
  console.log(`initialized ${configPath} from kit template`);
}

function loadUserConfig(
  configPath: string,
  kitDir: string,
  fallbackExample: boolean,
): JsonObject {
  if (existsSync(configPath)) return loadYaml(configPath);
  if (fallbackExample) {
    const example = configExamplePath(kitDir);
    if (existsSync(example)) return loadYaml(example);
  }
  return {};
}

function usage(): never {
  console.log(`Usage: kit-configure [options]

Options:
  --config PATH              Kit user settings (default: XDG config.yaml)
  --target cursor|claude|both  Which tool configs to update (default: both)
  --cli-config PATH          Cursor CLI config
  --claude-settings PATH     Claude Code settings
  --commits BOOL             Override commit attribution
  --prs BOOL                 Override PR attribution
  --disable-attribution      Disable commit and PR attribution
  --enable-attribution       Enable commit and PR attribution
  --init-config              Copy config.yaml.example when missing
  --dry-run                  Print resulting JSON without writing
  -h, --help                 Show help`);
  process.exit(0);
}

function main(): void {
  const args = process.argv.slice(2);
  let config: string | null = null;
  let target: "cursor" | "claude" | "both" = "both";
  let cliConfig = join(homedir(), ".cursor", "cli-config.json");
  let claudeSettings = join(homedir(), ".claude", "settings.json");
  let commits: boolean | null = null;
  let prs: boolean | null = null;
  let disableAttribution = false;
  let enableAttribution = false;
  let initConfig = false;
  let dryRun = false;

  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-h" || a === "--help") usage();
    else if (a === "--config" || a.startsWith("--config=")) {
      config = a.includes("=") ? a.slice("--config=".length) : (args[++i] ?? "");
    } else if (a === "--target" || a.startsWith("--target=")) {
      const v = a.includes("=") ? a.slice("--target=".length) : args[++i];
      if (v !== "cursor" && v !== "claude" && v !== "both") {
        console.error(`Invalid --target: ${v}`);
        process.exit(1);
      }
      target = v;
    } else if (a === "--cli-config" || a.startsWith("--cli-config=")) {
      cliConfig = a.includes("=")
        ? a.slice("--cli-config=".length)
        : (args[++i] ?? cliConfig);
    } else if (a === "--claude-settings" || a.startsWith("--claude-settings=")) {
      claudeSettings = a.includes("=")
        ? a.slice("--claude-settings=".length)
        : (args[++i] ?? claudeSettings);
    } else if (a === "--commits" || a.startsWith("--commits=")) {
      commits = parseBool(
        a.includes("=") ? a.slice("--commits=".length) : (args[++i] ?? ""),
      );
    } else if (a === "--prs" || a.startsWith("--prs=")) {
      prs = parseBool(a.includes("=") ? a.slice("--prs=".length) : (args[++i] ?? ""));
    } else if (a === "--disable-attribution") disableAttribution = true;
    else if (a === "--enable-attribution") enableAttribution = true;
    else if (a === "--init-config") initConfig = true;
    else if (a === "--dry-run") dryRun = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(1);
    }
  }

  if (disableAttribution && enableAttribution) {
    console.error("Use only one of --disable-attribution or --enable-attribution");
    process.exit(1);
  }

  const kitDir = findKitRoot(import.meta.dir);
  const configPath = resolveKitConfigPath(config);
  const initRequested = initConfig || disableAttribution;
  if (initRequested) {
    initConfigFromExample(configPath, kitDir, dryRun);
  }

  const userConfig = loadUserConfig(
    configPath,
    kitDir,
    initRequested && !existsSync(configPath),
  );
  const registry = loadRegistryDefaults(kitDir);
  const kitCursor = (registry.cursor as JsonObject) ?? {};
  const kitClaude = (registry.claude as JsonObject) ?? {};
  const userCursor = (userConfig.cursor as JsonObject) ?? {};
  const userClaude = (userConfig.claude as JsonObject) ?? {};

  const globalAttr = (userConfig.attribution as JsonObject) ?? {};
  const cursorAttrSource: JsonObject = {
    attribution: {
      ...((kitCursor.attribution as JsonObject) ?? {}),
      ...globalAttr,
      ...((userCursor.attribution as JsonObject) ?? {}),
    },
  };
  const claudeAttrSource: JsonObject = {
    attribution: {
      ...((kitClaude.attribution as JsonObject) ?? {}),
      ...globalAttr,
      ...((userClaude.attribution as JsonObject) ?? {}),
    },
  };

  const [cursorCommits, cursorPrs] = resolveAttributionFlags(cursorAttrSource, {
    commits,
    prs,
    disable: disableAttribution,
    enable: enableAttribution,
  });
  const [claudeCommits, claudePrs] = resolveAttributionFlags(claudeAttrSource, {
    commits,
    prs,
    disable: disableAttribution,
    enable: enableAttribution,
  });

  if (target === "cursor" || target === "both") {
    const path = expandUser(cliConfig);
    applyCursorSettings(path, kitCursor, userCursor, {
      commits: cursorCommits,
      prs: cursorPrs,
      dryRun,
    });
    if (!dryRun) console.log(`wrote Cursor settings → ${path}`);
  }

  if (target === "claude" || target === "both") {
    const path = expandUser(claudeSettings);
    applyClaudeSettings(path, kitClaude, userClaude, {
      commits: claudeCommits,
      prs: claudePrs,
      dryRun,
    });
    if (!dryRun) console.log(`wrote Claude settings → ${path}`);
  }

  if (!dryRun && existsSync(configPath)) {
    console.log(`kit config: ${configPath}`);
  }
}

try {
  main();
} catch (e) {
  console.error(e instanceof Error ? e.message : String(e));
  process.exit(1);
}
