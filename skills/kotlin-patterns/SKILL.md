---
name: kotlin-patterns
description: Kotlin patterns — Gradle, coroutines, null safety, Android and Ktor. Load after stacks/kotlin profile.
user-invokable: false
---

# Kotlin patterns

Load after [stacks/kotlin](../stacks/kotlin/SKILL.md).

## Structure

- **Gradle Kotlin DSL** — `build.gradle.kts` and `settings.gradle.kts`; version catalogs (`libs.versions.toml`) for deps.
- **Modules** — separate `api` / `implementation` boundaries; Android `app` vs feature modules when applicable.
- **Packages** — match directory layout; one public top-level type per file when practical.

## Language

- Prefer **null-safe** APIs; avoid `!!` — use `?.`, `?:`, `requireNotNull`, or early returns.
- **Data classes** for DTOs; **sealed** types for closed hierarchies and UI/network states.
- **Coroutines** for async IO; structured concurrency with `supervisorScope` where failures must be isolated.

## Android (when applicable)

- UI state in ViewModel / presenter layer; collect flows with lifecycle-aware APIs.
- No secrets in `BuildConfig` committed to git; use local properties or CI secrets.
- Minimize work on main thread; use `Dispatchers.IO` for blocking IO.

## Server / Ktor (when applicable)

- Route handlers thin; domain logic in testable services.
- Validate input at boundaries; map errors to typed HTTP responses.

## Testing

- JUnit 5 + kotlinx-coroutines-test for suspend code.
- Prefer fakes over heavy mocks for repositories and clients.

## References

- [Kotlin docs](https://kotlinlang.org/docs/home.html)
- [Gradle Kotlin DSL](https://docs.gradle.org/current/userguide/kotlin_dsl.html)
