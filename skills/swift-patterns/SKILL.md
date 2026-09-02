---
name: swift-patterns
description: Swift patterns — SPM, SwiftUI, concurrency, testing. Load after stacks/swift profile.
user-invocable: false
---

# Swift patterns

Load after [stacks/swift](../stacks/swift/SKILL.md).

## Structure

- **SPM** — `Package.swift` at the package root, code in `Sources/<Target>/`, tests in
  `Tests/<Target>Tests/`; keep targets focused. New packages default to `swiftLanguageModes: [.v6]`.
- **Xcode apps** — thin views; business logic in types testable without UIKit/SwiftUI when possible.
- **Tuist** — `Project.swift` is the source of truth; do not hand-edit generated projects.

## SwiftUI and UIKit

- **SwiftUI** — state at the right level; prefer `@Observable` / `@State` over scattered `@StateObject` when on current OS targets.
- **Main thread** — UI updates on main actor; mark view models `@MainActor` when they drive UI.
- Avoid force-unwrap (`!`) and `try!` on user-facing paths.

## Concurrency

- Use `async/await` and structured concurrency; avoid unbounded `Task {}` without cancellation handling.
- Shared mutable state behind **actors** — an actor's stored properties are isolated to that
  instance. Serial queues only where an actor cannot be adopted yet.
- The **Swift 6 language mode** makes data races a compile-time error, not a runtime surprise:
  values crossing an isolation boundary must be `Sendable`, and every declaration is
  non-isolated, actor-isolated, or global-actor-isolated. Fix diagnostics by tightening
  isolation, not by reaching for `@unchecked Sendable`.

## Security and platform

- Secrets in **Keychain**, not UserDefaults or bundled plist.
- App Transport Security and privacy manifest (`PrivacyInfo.xcprivacy`) updated when adding sensitive APIs.

## Testing

- **Swift Testing** (`@Test`, `@Suite`, `#expect`, `#require`) ships with the Swift 6
  toolchain and Xcode 16 — no package dependency. It runs alongside XCTest, so migrate
  existing suites incrementally rather than in one pass.
- SPM: `swift test`; Xcode: scheme-based `xcodebuild test` in CI.
- `no such module 'Testing'` from `swift test` on macOS means `xcode-select -p` points at
  Command Line Tools, which ships no test libraries — switch it to `Xcode.app/Contents/Developer`.
- Prefer deterministic unit tests; UI tests for critical flows only.

## References

- [Swift docs](https://docs.swift.org/)
- [Swift Testing](https://github.com/swiftlang/swift-testing)
- [Swift 6 migration guide](https://www.swift.org/migration/documentation/migrationguide)
- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
