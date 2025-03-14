//
//  HTMLParserTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-03-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class HTMLParserTests: XCTestCase {

    private var parser: HTMLParsing!
    private var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()

        mockLogger = MockLogger()
        parser = HTMLParser(logger: mockLogger)
    }

    override func tearDown() {
        parser = nil
        mockLogger = nil
        super.tearDown()
    }

    func testParseHTMLDescription_withValidHTML() {
        let html = """
        <p> Flowers die. Chocolate melts. A Windscribe Gift Card? Now that’s long-term commitment.</p>
        <p><a href="https://windscribe.com/upgrade?gift=1&pcpid=2025_Valentines_Day_Gifting_notif" target="_blank" class="ncta">Gift Privacy</a></p>
        """

        let result = parser.parse(description: html)

        XCTAssertEqual(result.message,
            "Flowers die. Chocolate melts. A Windscribe Gift Card? Now that’s long-term commitment.")

        XCTAssertNotNil(result.actionLink)
        XCTAssertEqual(result.actionLink?.title, "Gift Privacy")
        XCTAssertEqual(result.actionLink?.link, "https://windscribe.com/upgrade?gift=1&pcpid=2025_Valentines_Day_Gifting_notif")
    }

    func testParseHTMLDescription_withComplexLinkStructure() {
        let html = """
        <p> Flowers die. Chocolate melts. A Windscribe Gift Card? Now that’s long-term commitment.</p>
        <p>
            <a href="https://windscribe.com/upgrade?gift=1&pcpid=2025_Valentines_Day_Gifting_notif"
               target="_blank"
               class="ncta">Gift Privacy</a>
        </p>
        """

        let result = parser.parse(description: html)

        XCTAssertEqual(result.message,
            "Flowers die. Chocolate melts. A Windscribe Gift Card? Now that’s long-term commitment.")

        XCTAssertNotNil(result.actionLink)
        XCTAssertEqual(result.actionLink?.title, "Gift Privacy")
        XCTAssertEqual(result.actionLink?.link, "https://windscribe.com/upgrade?gift=1&pcpid=2025_Valentines_Day_Gifting_notif")
    }

    func testParseHTMLDescription_withMessageAndNoLink() {
        let html = """
        <p>This is a message without a link.</p>
        <p>Another paragraph.</p>
        """

        let result = parser.parse(description: html)

        XCTAssertEqual(result.message,
            "This is a message without a link.\nAnother paragraph.")

        XCTAssertNil(result.actionLink)  // ✔️ Correctly returns `nil` for the link
    }

    func testParseHTMLDescription_withEmptyHTML() {
        let html = ""
        let result = parser.parse(description: html)

        XCTAssertEqual(result.message, "")
        XCTAssertNil(result.actionLink)
    }

    func testParseHTMLDescription_withNoParagraphs() {
        let html = "This is plain text with no <p> tags."
        let result = parser.parse(description: html)

        XCTAssertEqual(result.message, "This is plain text with no <p> tags.")
        XCTAssertNil(result.actionLink)
    }
}
