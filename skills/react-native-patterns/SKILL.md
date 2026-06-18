---
name: react-native-patterns
description: React Native patterns — navigation, lists, native modules, platform APIs. Load after stacks/react-native profile.
user-invokable: false
---

# React Native patterns

Load after [stacks/react-native](../stacks/react-native/SKILL.md).

## Structure

- **Screens** thin; business logic in hooks, services, or state modules testable without the renderer.
- **Platform splits** — `*.ios.tsx` / `*.android.tsx` only when behavior truly differs; share logic in `.ts` modules.
- **Assets** — vector icons and images via project convention; avoid hard-coded remote URLs in components.

## UI and performance

- **Lists** — `FlatList` / `FlashList` with stable `keyExtractor`; memoize row components; avoid inline anonymous functions in hot paths when profiling shows cost.
- **Navigation** — typed routes (React Navigation or Expo Router per project); params validated at boundaries.
- Avoid anonymous `useEffect` fetches without cleanup and cancellation.

## Native and platform

- Prefer **Expo modules** or well-maintained libraries before custom native code.
- Custom **native modules** — thin bridges; validate inputs; document threading expectations.
- Permissions requested in context with rationale; handle denied states in UI.

## Security

- No API keys in JS bundles — use secure storage, remote config, or build-time env via CI secrets.
- Deep links and universal links validated before navigation side effects.

## Testing

- Jest + React Native Testing Library for components and hooks.
- Detox / Maestro for critical E2E flows when project already uses them.

## References

- [React Native docs](https://reactnative.dev/docs/getting-started)
- [Expo docs](https://docs.expo.dev/) (when applicable)
