//
//  AboutTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("AboutViewModel")
@MainActor
struct AboutViewModelTests {

    // MARK: - Initialisation

    @Test("Initialises with the current dark-mode snapshot — light")
    func initialDarkMode_lightSnapshot() {
        let mock = MockLookAndFeelObserving(initialIsDarkMode: false)
        let vm = AboutViewModel(lookAndFeel: mock)
        #expect(vm.isDarkMode == false)
    }

    @Test("Initialises with the current dark-mode snapshot — dark")
    func initialDarkMode_darkSnapshot() {
        let mock = MockLookAndFeelObserving(initialIsDarkMode: true)
        let vm = AboutViewModel(lookAndFeel: mock)
        #expect(vm.isDarkMode == true)
    }

    @Test("Seeds entries in the documented order")
    func entriesOrder() {
        let vm = AboutViewModel(lookAndFeel: MockLookAndFeelObserving())
        #expect(vm.entries == [
            .status, .aboutUs, .privacyPolicy, .terms,
            .blog, .jobs, .softwareLicenses, .changelog
        ])
    }

    // MARK: - Actions

    @Test("entrySelected sets safariURL from the entry's url")
    func entrySelected_setsSafariURL() {
        let vm = AboutViewModel(lookAndFeel: MockLookAndFeelObserving())
        vm.entrySelected(.privacyPolicy)
        #expect(vm.safariURL?.absoluteString == Links.privacy)
    }

    @Test(
        "entrySelected covers every AboutItemType",
        arguments: [
            AboutItemType.status, .aboutUs, .privacyPolicy, .terms,
            .blog, .jobs, .softwareLicenses, .changelog
        ]
    )
    func entrySelected_allTypes(_ entry: AboutItemType) {
        let vm = AboutViewModel(lookAndFeel: MockLookAndFeelObserving())
        vm.entrySelected(entry)
        #expect(vm.safariURL?.absoluteString == entry.url)
    }

    // MARK: - Dark-mode observation

    @Test("observeDarkMode reflects stream emissions")
    func observeDarkMode_emitsCurrentThenUpdates() async throws {
        let mock = MockLookAndFeelObserving(initialIsDarkMode: false)
        let vm = AboutViewModel(lookAndFeel: mock)

        let task = Task { await vm.observeDarkMode() }
        defer { task.cancel() }

        // First emission is the current value (per CurrentValueSubject semantics).
        try await waitForDarkMode(vm, toBe: false)

        mock.send(true)
        try await waitForDarkMode(vm, toBe: true)

        mock.send(false)
        try await waitForDarkMode(vm, toBe: false)
    }

    /// Polls `vm.isDarkMode` for up to `timeout` waiting for it to equal
    /// `expected`. Asserts equality at the end so a timeout produces a
    /// failing expectation rather than a silent skip.
    ///
    /// Polling rather than `Task.yield()` is deliberate: a single yield
    /// isn't enough to drive an `AsyncStream` consumer through a value
    /// reliably (the consumer task may need multiple resumption hops).
    /// 5 ms steps with a 200 ms ceiling gives a deterministic test.
    private func waitForDarkMode(
        _ vm: AboutViewModel,
        toBe expected: Bool,
        timeout: Duration = .milliseconds(200)
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while vm.isDarkMode != expected && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(vm.isDarkMode == expected)
    }
}

// MARK: - Mock

final class MockLookAndFeelObserving: LookAndFeelObserving, @unchecked Sendable {
    private(set) var isDarkMode: Bool
    private var continuation: AsyncStream<Bool>.Continuation?

    init(initialIsDarkMode: Bool = false) {
        self.isDarkMode = initialIsDarkMode
    }

    var darkModeUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.isDarkMode)
        }
    }

    func send(_ value: Bool) {
        isDarkMode = value
        continuation?.yield(value)
    }
}
