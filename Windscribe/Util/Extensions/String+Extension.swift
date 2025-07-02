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
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData?.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData!.count), digestBytes)
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

    var utf8Encoded: Data {
        return data(using: .utf8)!
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
        if suffix.isEmpty {
            return String(prefix)
        } else {
            return "\(prefix)-\(suffix)"
        }
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
}
