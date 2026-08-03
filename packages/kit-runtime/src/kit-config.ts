import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

export type KitProjectConfig = {
  spec_language: string;
  gates: Array<{ id: string; severity?: string }>;
};

const DEFAULTS: KitProjectConfig = {
  spec_language: "en",
  gates: [],
};

/**
 * Load optional `.ai/kit.yaml` (spec_language, gates).
 * Rejects legacy key `spec_locale` with a clear error for callers to surface.
 */
export function loadKitProjectConfig(projectPath: string): {
  config: KitProjectConfig;
  path: string | null;
  error?: string;
} {
  const path = join(projectPath, ".ai", "kit.yaml");
  if (!existsSync(path)) {
    return { config: { ...DEFAULTS }, path: null };
  }
  try {
    const raw = Bun.YAML.parse(readFileSync(path, "utf8")) as Record<
      string,
      unknown
    > | null;
    if (!raw || typeof raw !== "object") {
      return { config: { ...DEFAULTS }, path };
    }
    if ("spec_locale" in raw && raw.spec_locale != null) {
      return {
        config: { ...DEFAULTS },
        path,
        error:
          "`.ai/kit.yaml` uses deprecated key `spec_locale`; rename to `spec_language`",
      };
    }
    const gatesRaw = Array.isArray(raw.gates) ? raw.gates : [];
    const gates = gatesRaw
      .map((g) => {
        if (!g || typeof g !== "object") return null;
        const obj = g as Record<string, unknown>;
        if (typeof obj.id !== "string") return null;
        return {
          id: obj.id,
          severity: typeof obj.severity === "string" ? obj.severity : undefined,
        };
      })
      .filter(Boolean) as Array<{ id: string; severity?: string }>;

    return {
      config: {
        spec_language:
          typeof raw.spec_language === "string" && raw.spec_language
            ? raw.spec_language
            : DEFAULTS.spec_language,
        gates,
      },
      path,
    };
  } catch (e) {
    return {
      config: { ...DEFAULTS },
      path,
      error: `failed to parse .ai/kit.yaml: ${e}`,
    };
  }
}
