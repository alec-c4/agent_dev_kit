---
name: flutter-patterns
description: Flutter patterns — widgets, state, navigation, async, and platform integration. Load after stacks/flutter profile.
user-invokable: false
---

# Flutter patterns

Load after [stacks/flutter](../stacks/flutter/SKILL.md).

## Structure

- **Feature folders** — `lib/features/<name>/` with widgets, controllers/notifiers, and repositories.
- **Widgets** small and composable; extract when build methods grow or reuse appears twice.
- **Constants and theme** — `ThemeData` and design tokens; no magic numbers scattered in widgets.

## State

- Match project convention: **Provider**, **Riverpod**, **Bloc**, or **Cubit** — do not mix patterns in one feature without reason.
- Side effects (network, DB) in repositories/services; UI layer observes state only.
- Dispose controllers, `AnimationController`, and stream subscriptions in `dispose` / provider teardown.

## UI and performance

- **`const` constructors** where values are compile-time stable.
- Long lists — `ListView.builder` / slivers; avoid unbounded `Column` + `SingleChildScrollView` for large datasets.
- **`build` must stay pure** — no sync IO or hidden network in build methods.

## Platform

- **Platform channels** and plugins — validate inputs; document threading; prefer federated plugins.
- Permissions via supported plugins; handle denied/permanent-deny UX.

## Security

- Secrets via `--dart-define-from-file`, remote config, or secure storage — not committed in source.
- Validate deep links before navigation side effects.

## Testing

- `flutter test` for unit and widget tests; `integration_test` for critical flows when project uses it.
- Golden tests for stable UI when team already maintains them.

## References

- [Flutter docs](https://docs.flutter.dev/)
- [Dart docs](https://dart.dev/guides)
