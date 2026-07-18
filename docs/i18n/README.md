# Documentation translations

English is the **canonical** language for Agent Dev Kit docs. Guidelines (`docs/guidelines/`), `AGENTS.md`, skills, and registry YAML are maintained in English so all AI assistants share one source of truth.

Translations help humans read overview and onboarding material in their language. They **supplement** canonical docs — they do not replace them for agent routing unless a project explicitly opts in.

## Available locales

Registry: [registry/locales.yaml](../../registry/locales.yaml) (compiled to `locales.json`).

| Locale | README | Status |
|--------|--------|--------|
| English (`en`) | [README.md](../../README.md) | Canonical — full kit |
| Russian (`ru`) | [docs/i18n/ru/README.md](ru/README.md) | README translated |
| Spanish (`es`) | [docs/i18n/es/README.md](es/README.md) | README translated |

Add a row here when you ship a new locale or translate more files.

## Directory layout

```text
docs/i18n/
├── README.md          ← this file (English)
├── ru/
│   └── README.md      ← Russian README (canonical: README.md)
└── es/
    └── README.md      ← Spanish README (canonical: README.md)
```

Mirror the English path under `docs/i18n/<locale>/` when you translate nested docs, for example:

```text
docs/guidelines/WORKFLOW.md     → docs/i18n/ru/guidelines/WORKFLOW.md
docs/installation.md            → docs/i18n/es/installation.md
```

Keep **code blocks, CLI commands, file paths, and API identifiers** in English inside translations.

## Front matter

Every translated file starts with YAML front matter linking to the English source:

```yaml
---
locale: ru
canonical: README.md
---
```

For nested docs, `canonical` is the path from the repo root, for example `docs/guidelines/WORKFLOW.md`.

## Language switcher

Each translated README includes links to other locales at the top. When you add a locale:

1. Register it in `registry/locales.yaml`
2. Run `./scripts/kit compile`
3. Add switcher links to every locale README (including English root `README.md`)

## Contributing a translation

1. Edit the **English** source first — translations follow canonical changes.
2. Add or update files under `docs/i18n/<locale>/`.
3. Register the locale and file paths in `registry/locales.yaml`.
4. Run `./scripts/kit compile` and `./scripts/kit validate`.
5. Open a PR — one locale or one doc set per PR when possible.

Do not translate user-facing product copy inside skills or app templates unless the target project uses that locale — this kit's i18n is for **developer documentation** only.

## Validation

`./scripts/kit validate` checks that:

- `registry/locales.json` exists and matches `locales.yaml`
- Each locale `readme` path exists on disk
- Each registered translation path exists
- Translated files declare `canonical:` in front matter

## Future

Guidelines and installation guides may gain per-locale mirrors as contributors add them. Agent entry points (`AGENTS.md`, skills) stay English unless a project fork documents otherwise.
