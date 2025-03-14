//
//  MockHTMLParser.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-03-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

@testable import Windscribe

class MockHTMLParser: HTMLParsing {
    func parse(description: String) -> ParsedContent {
        return ParsedContent(
            message: "Mock message content.",
            actionLink: ActionLink(title: "Mock Link", link: "https://mock.link")
        )
    }
}
