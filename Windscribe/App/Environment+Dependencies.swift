//
//  Environment+Dependencies.swift
//  Windscribe
//
//  Project Neo composition root for SwiftUI `@Environment(@Entry)` values.
//  See docs/PROJECT_NEO.md.
//
//  This file is the one place where Neo features connect to the legacy
//  Swinject graph. Feature modules consume protocols via `@Environment`;
//  the `@Entry` defaults below resolve the legacy implementations on
//  first access. New protocols added in later PRs land here too.
//

import SwiftUI
import Swinject

@available(iOS 17.0, *)
extension EnvironmentValues {
    /// Look-and-feel observation surface (dark-mode state + updates).
    /// Default: adapter wrapping the Swinject-resolved legacy repository.
    @Entry var lookAndFeel: any LookAndFeelObserving = LegacyLookAndFeelObserver(
        repository: Assembler.resolve(LookAndFeelRepositoryType.self)
    )
}
