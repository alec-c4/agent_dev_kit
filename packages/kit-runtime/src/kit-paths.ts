import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

/**
 * One config home for the whole kit.
 *
 * Two spellings shipped: `agent_dev_kit` (tool settings) and `agent-dev-kit`
 * (projects and lessons). The hyphenated form is canonical; the underscored
 * one is still read so an existing install keeps working.
 */
const CANONICAL = "agent-dev-kit";
const LEGACY = "agent_dev_kit";

function configHome(): string {
  const xdg = process.env.XDG_CONFIG_HOME;
  if (xdg) {
    return xdg === "~"
      ? homedir()
      : xdg.startsWith("~/")
        ? join(homedir(), xdg.slice(2))
        : xdg;
  }
  return join(homedir(), ".config");
}

/** Canonical directory for new files. */
export function kitConfigDir(): string {
  return join(configHome(), CANONICAL);
}

/**
 * Path to read for `name`: the canonical location, unless only a legacy
 * `agent_dev_kit/` copy exists.
 */
export function kitConfigPath(name: string): string {
  const canonical = join(configHome(), CANONICAL, name);
  if (existsSync(canonical)) return canonical;
  const legacy = join(configHome(), LEGACY, name);
  if (existsSync(legacy)) return legacy;
  return canonical;
}

export function legacyKitConfigDir(): string {
  return join(configHome(), LEGACY);
}
