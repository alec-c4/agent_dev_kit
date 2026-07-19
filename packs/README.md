# Stack packs — optional skill bundles per technology

Install subsets with `./scripts/kit install --pack=core,rails` or deploy after install:

```bash
./scripts/kit deploy-skills --pack=rails --scope=project
```

| Pack | ID | Skills | Use when |
|------|-----|--------|----------|
| Universal Core | `core` | 32 | Always — stack profiles + workflow |
| Stack Patterns | `patterns` | 30 | All framework and DevOps pattern skills |
| Cross-cutting Topics | `topics` | 4 | Security, LLM, RAG, MCP |
| Rails | `rails` | 10 | Importmap, Hotwire, API, jsbundling/Vite, Inertia + React/Vue/Svelte |
| Frontend / Node | `node` | 4 | Next.js, Nuxt, SvelteKit, Svelte |
| Python | `python` | 2 | Django, FastAPI |
| Go | `go` | 1 | Go services |
| Elixir | `elixir` | 1 | Phoenix / LiveView |
| DevOps | `devops` | 4 | Docker, Kubernetes, Ansible, Terraform |
| Astro | `astro` | 1 | Astro content sites and hybrid apps |
| Tauri | `tauri` | 1 | Tauri desktop apps (Rust + webview) |
| Swift | `swift` | 1 | Swift / SwiftUI / SPM / Xcode projects |
| Kotlin | `kotlin` | 1 | Kotlin / Gradle / Android / JVM projects |
| React Native | `react-native` | 1 | React Native iOS and Android apps |
| Flutter | `flutter` | 1 | Flutter / Dart mobile and multi-platform apps |

**Default install** deploys `core`, `patterns`, and `topics`. Stack packs are optional slices of `patterns` for smaller installs.

Community packs: [community/README.md](community/README.md).

## depends_on

Manifests list `depends_on: [core]`. `deploy-skills.sh` installs dependencies first.

## Add a pack

See [docs/EXTENDING.md](../docs/EXTENDING.md) and [community/_template/](community/_template/).
