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
    @Test("Seeds entries in the documented order")
    func entriesOrder() {
        let vm = AboutViewModel()
        #expect(vm.entries == [
            .status, .aboutUs, .privacyPolicy, .terms,
            .blog, .jobs, .softwareLicenses, .changelog
        ])
    }

    // MARK: - Actions

    @Test("entrySelected sets safariURL from the entry's url")
    func entrySelected_setsSafariURL() {
        let vm = AboutViewModel()
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
        let vm = AboutViewModel()
        vm.entrySelected(entry)
        #expect(vm.safariURL?.absoluteString == entry.url)
    }
}
