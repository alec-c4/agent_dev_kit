import { describe, expect, test } from "bun:test";
import {
  classify,
  monthsSince,
  parseAcceptedNames,
  parseRelease,
  parseVerifyClaims,
  registryUrl,
} from "../src/doc-verify.ts";

const NOW = new Date("2026-09-02T00:00:00Z");

describe("verify claims in frontmatter", () => {
  test("reads declared packages per ecosystem", () => {
    const md = `---
name: demo
description: x
metadata:
  verify:
    gem: [pundit, cancancan]
    npm: ["@inertiajs/svelte"]
---

body`;
    expect(parseVerifyClaims(md)).toEqual([
      { ecosystem: "gem", name: "pundit" },
      { ecosystem: "gem", name: "cancancan" },
      { ecosystem: "npm", name: "@inertiajs/svelte" },
    ]);
  });

  test("a skill without the block declares nothing", () => {
    expect(parseVerifyClaims("---\nname: demo\n---\n")).toEqual([]);
    expect(parseVerifyClaims("no frontmatter at all")).toEqual([]);
  });

  test("unknown ecosystems and non-string entries are ignored", () => {
    const md = `---
name: demo
metadata:
  verify:
    gem: [ok, 42, ""]
    deb: [ignored]
---
`;
    expect(parseVerifyClaims(md)).toEqual([{ ecosystem: "gem", name: "ok" }]);
  });

  test("malformed frontmatter does not throw", () => {
    expect(parseVerifyClaims("---\n: : :\n---\n")).toEqual([]);
  });
});

describe("release age", () => {
  test("months are counted from the release date", () => {
    expect(monthsSince("2026-08-01T00:00:00Z", NOW)).toBe(1);
    expect(monthsSince("2024-09-02T00:00:00Z", NOW)).toBe(24);
    expect(monthsSince(null, NOW)).toBeNull();
    expect(monthsSince("not-a-date", NOW)).toBeNull();
  });

  test("a recent release is current", () => {
    expect(classify("2026-07-15T00:00:00Z", NOW).verdict).toBe("current");
  });

  test("quiet for over 18 months is stale", () => {
    expect(classify("2024-11-01T00:00:00Z", NOW).verdict).toBe("stale");
  });

  test("quiet for over 36 months is abandoned", () => {
    // the cancan case: last release 2013
    expect(classify("2013-05-07T00:00:00Z", NOW).verdict).toBe("abandoned");
  });

  test("an unknown date is not reported as a problem", () => {
    expect(classify(null, NOW).verdict).toBe("current");
  });
});

describe("registry shapes", () => {
  test("each ecosystem gets its own endpoint", () => {
    expect(registryUrl({ ecosystem: "gem", name: "pundit" })).toContain("rubygems.org");
    expect(registryUrl({ ecosystem: "npm", name: "@inertiajs/svelte" })).toBe(
      "https://registry.npmjs.org/@inertiajs/svelte",
    );
    expect(registryUrl({ ecosystem: "hex", name: "phoenix" })).toContain("hex.pm");
    expect(registryUrl({ ecosystem: "crate", name: "serde" })).toContain("crates.io");
    expect(registryUrl({ ecosystem: "pypi", name: "fastapi" })).toContain("pypi.org");
  });

  test("rubygems", () => {
    expect(
      parseRelease("gem", { version: "3.6.1", version_created_at: "2024-05-28T04:10:35Z" }),
    ).toEqual({ version: "3.6.1", released: "2024-05-28T04:10:35Z" });
  });

  test("npm resolves the date through dist-tags", () => {
    expect(
      parseRelease("npm", {
        "dist-tags": { latest: "2.0.0" },
        time: { "1.0.0": "2020-01-01T00:00:00Z", "2.0.0": "2026-01-01T00:00:00Z" },
      }),
    ).toEqual({ version: "2.0.0", released: "2026-01-01T00:00:00Z" });
  });

  test("pypi", () => {
    expect(
      parseRelease("pypi", {
        info: { version: "0.115.0" },
        releases: { "0.115.0": [{ upload_time_iso_8601: "2026-02-02T00:00:00Z" }] },
      }),
    ).toEqual({ version: "0.115.0", released: "2026-02-02T00:00:00Z" });
  });

  test("hex", () => {
    expect(
      parseRelease("hex", {
        latest_stable_version: "1.7.0",
        releases: [{ version: "1.7.0", inserted_at: "2026-03-03T00:00:00Z" }],
      }),
    ).toEqual({ version: "1.7.0", released: "2026-03-03T00:00:00Z" });
  });

  test("crates.io", () => {
    expect(
      parseRelease("crate", {
        crate: { max_stable_version: "1.0.0", updated_at: "2026-04-04T00:00:00Z" },
        versions: [{ num: "1.0.0", created_at: "2026-04-01T00:00:00Z" }],
      }),
    ).toEqual({ version: "1.0.0", released: "2026-04-01T00:00:00Z" });
  });

  test("an unexpected body yields no release", () => {
    expect(parseRelease("gem", {})).toBeNull();
    expect(parseRelease("npm", null)).toBeNull();
  });
});

describe("accepted staleness", () => {
  const md = `---
name: demo
metadata:
  verify:
    gem: ["rolify", "pundit"]
    accept: ["rolify"]
---
`;

  test("accept names are read", () => {
    expect([...parseAcceptedNames(md)]).toEqual(["rolify"]);
  });

  test("accept does not remove the package from the claim list", () => {
    expect(parseVerifyClaims(md).map((c) => c.name)).toEqual(["rolify", "pundit"]);
  });

  test("a skill without accept accepts nothing", () => {
    expect(parseAcceptedNames("---\nname: d\n---\n").size).toBe(0);
    expect(parseAcceptedNames("no frontmatter").size).toBe(0);
  });
});
