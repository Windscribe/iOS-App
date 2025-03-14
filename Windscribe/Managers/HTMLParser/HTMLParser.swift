//
//  HTMLParser.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

struct ParsedContent {
    let message: String
    let actionLink: ActionLink?
}

class HTMLParser: HTMLParsing {

    let logger: FileLogger

    init (logger: FileLogger) {
        self.logger = logger
    }

    func parse(description: String) -> ParsedContent {
        let paragraphPattern = "<p[^>]*>(.*?)</p>"

//        let linkPattern = #"<a[^>]*\bclass\s*=\s*["']ncta["'][^>]*\bhref\s*=\s*["'](.*?)["'][^>]*>(.*?)</a>"#

        let linkPattern = #"<a[^>]*href=["'](.*?)["'][^>]*class=["']ncta["'][^>]*>(.*?)</a>"#

        print("🔍 Raw Description: [\(description)]")

        do {
            let paragraphRegex = try NSRegularExpression(pattern: paragraphPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let linkRegex = try NSRegularExpression(pattern: linkPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])

            let nsDescription = description as NSString
            let paragraphs = paragraphRegex.matches(in: description, range: NSRange(location: 0, length: nsDescription.length))

            var messageArray: [String] = []

            for match in paragraphs {
                let paragraph = nsDescription.substring(with: match.range)

                if linkRegex.firstMatch(in: paragraph, range: NSRange(location: 0, length: paragraph.count)) == nil {
                    let cleanedParagraph = paragraph
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !cleanedParagraph.isEmpty {
                        messageArray.append(cleanedParagraph)
                    }
                }
            }

            let message = messageArray.joined(separator: "\n")

            // Link extraction logic
            var actionLink: ActionLink?
            if let linkMatch = linkRegex.firstMatch(in: description, range: NSRange(location: 0, length: nsDescription.length)) {
                let url = nsDescription.substring(with: linkMatch.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let linkText = nsDescription.substring(with: linkMatch.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)

                print("🔗 Extracted URL: [\(url)]")
                print("🔗 Extracted Link Text: [\(linkText)]")

                actionLink = ActionLink(title: linkText, link: url)
            }

            if !message.isEmpty {
                return ParsedContent(message: message, actionLink: actionLink)
            } else {
                return ParsedContent(message: description, actionLink: nil)
            }

        } catch {
            logger.logE("HTMLParser", "Error parsing HTML content: \(error)")
            return ParsedContent(message: description, actionLink: nil)
        }
    }
}
