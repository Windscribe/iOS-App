# WindscribeTV/Features/

Project Neo lives here for tvOS. New tvOS features go in this directory; legacy
UIKit screens stay in `WindscribeTV/UI/` until they are rebuilt.

**Read first:**

- [`docs/PROJECT_NEO.md`](../../docs/PROJECT_NEO.md) — the rules every Neo file
  must follow (no Swinject, no Combine, no `ObservableObject`, etc.) and the
  "Applying these patterns to tvOS" section for focus-engine and remote-input
  affordances on top of the platform-shared stack.
- [`Windscribe/Features/About/`](../../Windscribe/Features/About/) — the canonical
  iOS reference module (per ND-005). The shape is platform-agnostic: copy it,
  swap the SwiftUI surface for the tvOS-appropriate views, keep the
  `@Observable` `@MainActor` view model and `@Environment(@Entry)`-injected
  protocol services unchanged.
- [`docs/neo/DECISIONS.md`](../../docs/neo/DECISIONS.md) and
  [`docs/neo/STATE.md`](../../docs/neo/STATE.md) — current architectural
  decisions and execution state.

**Enforcement:** SwiftLint custom rules in `.swiftlint.yml` (`neo_no_*`) apply
to this path automatically.
