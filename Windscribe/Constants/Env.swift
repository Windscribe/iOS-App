//
//  Env.swift
//  Windscribe
//
//  Single source of truth for compile-time build facts.
//

import Foundation

/// Centralized, compile-time-derived build environment facts.
///
/// Prefer these over scattering `#if STAGING` / `#if os(...)` through the codebase:
/// both branches stay compiled (so they're type-checked and can't silently rot) and
/// the intent reads as ordinary Swift.
///
/// Keep using a raw `#if` only where the inactive branch must be *excluded from the
/// binary* — conditional `import`s, platform-exclusive APIs, type/function declarations,
/// or anything that shouldn't ship in a release (e.g. `#if DEBUG` logging).
enum Env {

    // MARK: - Build configuration

    static let isDebug: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()

    /// Staging build — points WSNet at staging domains. Always also `isInternal`.
    static let isStaging: Bool = {
        #if STAGING
        true
        #else
        false
        #endif
    }()

    /// Internal (non-release) build. On for every build except a production release
    /// (CI strips the `INTERNAL` flag for `release-*` branches). Gates internal-only
    /// affordances such as verbose logging and the red INTERNAL app icon.
    static let isInternal: Bool = {
        #if INTERNAL
        true
        #else
        false
        #endif
    }()

    static let isProduction: Bool = {
        #if PRODUCTION
        true
        #else
        false
        #endif
    }()

    // MARK: - Platform

    static let isIOS: Bool = {
        #if os(iOS)
        true
        #else
        false
        #endif
    }()

    static let isTVOS: Bool = {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }()
}
