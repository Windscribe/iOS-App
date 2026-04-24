//
//  String+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import CommonCrypto
import UIKit

extension String {
    var messageData: Data? {
        return data(using: .utf8)
    }

    func base64Encoded() -> String {
        if let data = data(using: .utf8) {
            return data.base64EncodedString()
        }
        return ""
    }

    func base64Decoded() -> String {
        if let data = Data(base64Encoded: self), let value = String(data: data, encoding: .utf8) {
            return value
        }
        return ""
    }

    func MD5() -> String {
        guard let messageData = messageData else { return "" }

        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                let digestBytesPtr = digestBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
                let messageBytesPtr = messageBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
                CC_MD5(messageBytesPtr, CC_LONG(messageData.count), digestBytesPtr)
            }
        }
        let hex = digestData.map { String(format: "%02hhx", $0) }.joined()
        return hex
    }

    func withIcon(icon: UIImage, bounds: CGRect, textColor: UIColor) -> NSAttributedString {
        let completeText = NSMutableAttributedString(string: "")
        let text = NSMutableAttributedString(string: "\(self) ")
        completeText.append(text)
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = icon
        imageAttachment.bounds = bounds
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        completeText.append(attachmentString)
        completeText.addAttribute(kCTForegroundColorAttributeName as NSAttributedString.Key, value: textColor, range: NSRange(location: 0, length: count))
        return completeText
    }

    func encodeForURL() -> String {
        return replacingOccurrences(of: "+", with: "%2B")
    }

    func maxLength(length: Int) -> String {
        var str = self
        let nsString = str as NSString
        if nsString.length >= length {
            str = nsString.substring(with:
                NSRange(
                    location: 0,
                    length: nsString.length > length ? length : nsString.length
                )
            )
        }
        return str
    }

    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }

    func formatIpAddress() -> String {
        let ip = trimmingCharacters(in: CharacterSet.newlines)
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()
        if ip.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
            return ip
        } else if ip.trimmingCharacters(in: CharacterSet.newlines).withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            return ip
        } else {
            return "---.---.---.---"
        }
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    var utf8Encoded: Data? {
        return data(using: .utf8)
    }

    func getIPOctects() -> [String] {
        let ipRegex = "([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})"
        do {
            let regex = try NSRegularExpression(pattern: ipRegex)
            let results = regex.matches(in: self,
                                        range: NSRange(startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // Adds the dash in XXXX-XXXX format
    func formattedLazyLoginCode() -> String {
        let clean = self
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(8)
        let prefix = clean.prefix(4)
        let suffix = clean.dropFirst(4)
        let result: String
        if suffix.isEmpty {
            result = String(prefix)
        } else {
            result = "\(prefix)-\(suffix)"
        }
        return result
    }

    func areSubdomainsEqual(other hostName: String) -> Bool {
        guard let firstSubDomain = self.split(separator: ".").dropLast().first else { return false }
        guard let secondSubDomain = hostName.split(separator: ".").dropLast().first else { return false }
        return firstSubDomain == secondSubDomain
    }

    /// Returns a redacted copy of the string with the middle portion replaced by asterisks.
    ///
    /// The prefix and suffix each show up to 5 characters (always equal length),
    /// and the redacted middle uses up to 5 `*` characters regardless of actual hidden length.
    ///
    /// Edge cases:
    /// - Length 0: returns `""`
    /// - Length 1: returns `"*"`
    /// - Length 2: returns first char + `"*"`
    /// - Length 3: returns first char + `"*"` + last char
    var redacted: String {
        let length = count

        guard length > 0 else { return "" }
        guard length > 1 else { return "*" }
        guard length > 2 else { return String(first!) + "*" }
        guard length > 3 else { return String(first!) + "*" + String(last!) }

        // For strings longer than 3 characters:
        // Show up to 5 prefix chars and up to 5 suffix chars (equal length),
        // with up to 5 asterisks in the middle.
        let maxReveal = 5
        // Each side can show at most half the non-middle portion, capped at maxReveal
        let sideLength = min(maxReveal, (length - 1) / 2)
        let hiddenLength = length - (sideLength * 2)
        let asterisks = String(repeating: "*", count: min(hiddenLength, 5))

        let prefixStr = String(prefix(sideLength))
        let suffixStr = String(suffix(sideLength))

        return prefixStr + asterisks + suffixStr
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }

    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }

    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }

    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex, let range = self[startIndex...].range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }

    /// Returns the IP address with the last octet replaced by `***` for privacy.
    /// Works for both IPv4 (e.g. `1.2.3.4` → `1.2.3.***`) and IPv6 (last group redacted).
    /// Returns the original string unchanged if it doesn't look like an IP address.
    var redactedIP: String {
        if contains(".") {
            // IPv4: replace last octet
            if let lastDot = lastIndex(of: ".") {
                return String(self[self.startIndex...lastDot]) + "***"
            }
        } else if contains(":") {
            // IPv6: replace last group
            if let lastColon = lastIndex(of: ":") {
                return String(self[self.startIndex...lastColon]) + "***"
            }
        }
        return String(self)
    }
}
