import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

export type ProcessReferences = "omit" | "allow";

export type KitProjectConfig = {
  spec_language: string;
  process_references: ProcessReferences;
  gates: Array<{ id: string; severity?: string }>;
  wiki_index: boolean;
  pattern_checks: boolean;
};

const DEFAULTS: KitProjectConfig = {
  spec_language: "en",
  process_references: "omit",
  gates: [],
  wiki_index: false,
  pattern_checks: true,
};

/**
 * Load optional `.ai/kit.yaml` (spec_language, process_references, gates, wiki_index).
 * Rejects legacy key `spec_locale` with a clear error for callers to surface.
 * Default process_references is `omit` (no plan/stage jargon in shipped artifacts).
 * Default wiki_index is `false` — see docs/guidelines/SPECS.md#index-and-log.
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

    let process_references: ProcessReferences = DEFAULTS.process_references;
    if ("process_references" in raw && raw.process_references != null) {
      if (
        raw.process_references !== "omit" &&
        raw.process_references !== "allow"
      ) {
        return {
          config: { ...DEFAULTS },
          path,
          error:
            "`.ai/kit.yaml` process_references must be `omit` or `allow`",
        };
      }
      process_references = raw.process_references;
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

    const wiki_index =
      typeof raw.wiki_index === "boolean"
        ? raw.wiki_index
        : DEFAULTS.wiki_index;

    const pattern_checks =
      typeof raw.pattern_checks === "boolean"
        ? raw.pattern_checks
        : DEFAULTS.pattern_checks;

    return {
      config: {
        spec_language:
          typeof raw.spec_language === "string" && raw.spec_language
            ? raw.spec_language
            : DEFAULTS.spec_language,
        process_references,
        gates,
        wiki_index,
        pattern_checks,
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
