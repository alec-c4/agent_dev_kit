---
name: swift-patterns
description: Swift patterns — SPM, SwiftUI, concurrency, testing. Load after stacks/swift profile.
user-invokable: false
---

# Swift patterns

Load after [stacks/swift](../stacks/swift/SKILL.md).

## Structure

- **SPM** — `Package.swift` at root or in modules; keep targets focused; tests in `Tests/`.
- **Xcode apps** — thin views; business logic in types testable without UIKit/SwiftUI when possible.
- **Tuist** — `Project.swift` is the source of truth; do not hand-edit generated projects.

## SwiftUI and UIKit

- **SwiftUI** — state at the right level; prefer `@Observable` / `@State` over scattered `@StateObject` when on current OS targets.
- **Main thread** — UI updates on main actor; mark view models `@MainActor` when they drive UI.
- Avoid force-unwrap (`!`) and `try!` on user-facing paths.

## Concurrency

- Use `async/await` and structured concurrency; avoid unbounded `Task {}` without cancellation handling.
- Shared mutable state behind actors or serial queues — document thread safety for non-UI services.

## Security and platform

- Secrets in **Keychain**, not UserDefaults or bundled plist.
- App Transport Security and privacy manifest (`PrivacyInfo.xcprivacy`) updated when adding sensitive APIs.

## Testing

- SPM: `swift test`; Xcode: scheme-based `xcodebuild test` in CI.
- Prefer deterministic unit tests; UI tests for critical flows only.

## References

- [Swift docs](https://docs.swift.org/)
- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
