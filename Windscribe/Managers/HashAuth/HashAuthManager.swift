//
//  HashAuthManager.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-02.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import CryptoKit
import Combine
import UIKit

protocol HashAuthManager {
    var accountHash: String { get }
    var accountHashPublisher: Published<String>.Publisher { get }
    var preImageData: Data { get }

    @discardableResult func regenerate() -> Bool
    func loadFromFile(_ data: Data)
    func copyHash()
    func hash(from data: Data) -> String
}

class HashAuthManagerImpl: HashAuthManager {

    @Published private(set) var accountHash: String = ""
    private(set) var preImageData: Data = Data()
    private let logger: FileLogger

    var accountHashPublisher: Published<String>.Publisher { $accountHash }

    init(logger: FileLogger) {
        self.logger = logger
    }

    @discardableResult
    func regenerate() -> Bool {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            logger.logE("HashAuthManager", "SecRandomCopyBytes failed with status \(status)")
            return false
        }
        preImageData = Data(bytes)
        accountHash = computeHash(from: preImageData)
        return true
    }

    func loadFromFile(_ data: Data) {
        preImageData = data
        accountHash = computeHash(from: data)
    }

    func copyHash() {
        UIPasteboard.general.string = accountHash
    }

    func hash(from data: Data) -> String {
        computeHash(from: data)
    }

    private func computeHash(from data: Data) -> String {
        let digest = SHA256.hash(data: data)
        let fullHex = digest.map { String(format: "%02x", $0) }.joined()
        return "0x" + fullHex.suffix(32)
    }
}
