/**
 * Machine-checkable claims declared by a skill.
 *
 * Skills name external packages in prose, and prose goes stale silently: a gem
 * whose last release predates the guidance, a module that moved, an integration
 * the upstream project deprecated. A skill declares what it depends on under the
 * documented `metadata` frontmatter key, which Claude Code ignores, and this
 * module turns those declarations into something a CI job can fail on.
 *
 *   metadata:
 *     verify:
 *       gem: [pundit, cancancan]
 *       npm: ["@inertiajs/svelte"]
 */

export const ECOSYSTEMS = ["gem", "npm", "pypi", "hex", "crate"] as const;
export type Ecosystem = (typeof ECOSYSTEMS)[number];

export type PackageClaim = { ecosystem: Ecosystem; name: string };

export type ReleaseInfo = { version: string; released: string | null };

/**
 * `unknown` exists so a throttled or offline registry never masquerades as a
 * missing package: only a definite 404 is `missing`, and only `missing` or
 * `abandoned` should fail a build.
 */
export type Verdict =
  | "current"
  | "stale"
  | "abandoned"
  | "missing"
  | "unknown"
  | "accepted";

export type PackageResult = PackageClaim & {
  verdict: Verdict;
  /**
   * What the age alone said, before `accept` was applied. Kept so an accepted
   * package that has crossed into abandoned territory can still be shown —
   * silencing it entirely would let the accept list outlive its reasoning.
   */
  underlying?: Verdict;
  version?: string;
  released?: string | null;
  months?: number | null;
};

/** Extract the `metadata.verify` block from SKILL.md frontmatter. */
/**
 * Packages whose age is deliberate — named as a legacy alternative, say. A gate
 * that cannot be told "yes, we know" gets muted wholesale, so accepting one
 * entry has to be cheaper than disabling the check.
 *
 *   metadata:
 *     verify:
 *       gem: ["rolify"]
 *       accept: ["rolify"]
 */
export function parseAcceptedNames(text: string): Set<string> {
  const m = text.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!m) return new Set();
  let data: unknown;
  try {
    data = Bun.YAML.parse(m[1]);
  } catch {
    return new Set();
  }
  const accept = (data as { metadata?: { verify?: { accept?: unknown } } } | null)
    ?.metadata?.verify?.accept;
  if (!Array.isArray(accept)) return new Set();
  return new Set(accept.filter((n): n is string => typeof n === "string"));
}

export function parseVerifyClaims(text: string): PackageClaim[] {
  const m = text.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!m) return [];
  let data: unknown;
  try {
    data = Bun.YAML.parse(m[1]);
  } catch {
    return [];
  }
  const meta = (data as { metadata?: { verify?: unknown } } | null)?.metadata;
  const verify = meta?.verify;
  if (!verify || typeof verify !== "object") return [];
  const out: PackageClaim[] = [];
  for (const eco of ECOSYSTEMS) {
    const names = (verify as Record<string, unknown>)[eco];
    if (!Array.isArray(names)) continue;
    for (const name of names) {
      if (typeof name === "string" && name.trim()) {
        out.push({ ecosystem: eco, name: name.trim() });
      }
    }
  }
  return out;
}

/**
 * Whole calendar months elapsed. An average-length month would report 23 for a
 * span a human reads as two years, which makes an "18 months" threshold lie.
 */
export function monthsSince(iso: string | null, now: Date): number | null {
  if (!iso) return null;
  const then = new Date(iso);
  if (Number.isNaN(then.getTime())) return null;
  let months =
    (now.getUTCFullYear() - then.getUTCFullYear()) * 12 +
    (now.getUTCMonth() - then.getUTCMonth());
  if (now.getUTCDate() < then.getUTCDate()) months -= 1;
  return Math.max(0, months);
}

/**
 * `stale` is a prompt to re-read the upstream docs, not a defect: a mature
 * package can sit still for years. `abandoned` is the CanCan case — guidance
 * pointing at something that stopped moving long ago.
 */
export function classify(
  released: string | null,
  now: Date,
  staleMonths = 18,
  abandonedMonths = 36,
): { verdict: Exclude<Verdict, "missing">; months: number | null } {
  const months = monthsSince(released, now);
  if (months === null) return { verdict: "current", months: null };
  if (months >= abandonedMonths) return { verdict: "abandoned", months };
  if (months >= staleMonths) return { verdict: "stale", months };
  return { verdict: "current", months };
}

export function registryUrl(claim: PackageClaim): string {
  const n = encodeURIComponent(claim.name);
  switch (claim.ecosystem) {
    case "gem":
      return `https://rubygems.org/api/v1/gems/${n}.json`;
    case "npm":
      return `https://registry.npmjs.org/${claim.name}`;
    case "pypi":
      return `https://pypi.org/pypi/${n}/json`;
    case "hex":
      return `https://hex.pm/api/packages/${n}`;
    case "crate":
      return `https://crates.io/api/v1/crates/${n}`;
  }
}

/** Normalise each registry's own shape into version + release date. */
export function parseRelease(eco: Ecosystem, body: unknown): ReleaseInfo | null {
  const d = body as Record<string, any>;
  if (!d || typeof d !== "object") return null;
  switch (eco) {
    case "gem":
      return d.version
        ? { version: String(d.version), released: d.version_created_at ?? null }
        : null;
    case "npm": {
      const latest = d["dist-tags"]?.latest;
      if (!latest) return null;
      return { version: String(latest), released: d.time?.[latest] ?? null };
    }
    case "pypi": {
      const v = d.info?.version;
      if (!v) return null;
      const files = d.releases?.[v];
      const released = Array.isArray(files) && files.length
        ? files[0].upload_time_iso_8601 ?? null
        : null;
      return { version: String(v), released };
    }
    case "hex": {
      const v = d.latest_stable_version ?? d.latest_version;
      if (!v) return null;
      const rel = (d.releases ?? []).find((r: any) => r.version === v);
      return { version: String(v), released: rel?.inserted_at ?? null };
    }
    case "crate": {
      const v = d.crate?.max_stable_version ?? d.crate?.max_version;
      if (!v) return null;
      const ver = (d.versions ?? []).find((r: any) => r.num === v);
      return { version: String(v), released: ver?.created_at ?? d.crate?.updated_at ?? null };
    }
  }
}

export type LinkVerdict = "ok" | "dead" | "unreachable";

/**
 * What a status code actually says about a documentation link.
 *
 * Only 404 and 410 are the server telling us the page is gone. A 429 is the
 * host rate-limiting the caller, a 5xx is the host having a bad minute, and a
 * 401/403 is usually a bot wall in front of a page that is perfectly fine —
 * none of those are claims about the link. Treating them as failures is how a
 * scheduled run reported docs.ansible.com as broken while it served 200 to
 * everyone else.
 *
 * A status of 0 means the request never completed (timeout, DNS, TLS).
 */
export function classifyLink(status: number): LinkVerdict {
  if (status >= 200 && status < 400) return "ok";
  if (status === 404 || status === 410) return "dead";
  return "unreachable";
}

/** Statuses worth trying again: the host is throttling or briefly unwell. */
export function isRetryableStatus(status: number): boolean {
  return status === 429 || (status >= 500 && status < 600);
}
