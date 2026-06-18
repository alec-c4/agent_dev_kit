---
name: changelog
description: Draft user-facing changelog entries from spec changelog and merged PRs. Use before release notes or VERSION bump.
user-invokable: false
---

# Changelog helper

Turn **spec version bumps** and **merged PRs** into readable release notes. Follow project format if `CHANGELOG.md` exists.

## Input

- Spec `## Changelog` sections ([SPECS.md](../../docs/guidelines/SPECS.md))
- `.ai/pr-summary.md` or PR descriptions
- Conventional commit subjects ([COMMITS.md](../../docs/guidelines/COMMITS.md))

## Output sections

Use [Keep a Changelog](https://keepachangelog.com/) headings when unspecified:

- **Added**, **Changed**, **Fixed**, **Removed**, **Security**

## Rules

- User-facing language; link issues as `GH-NN` when `work_ref` known.
- Breaking changes need migration note.
- No AI attribution in changelog text.
