//
//  WireguardIPGenerator.swift
//  Windscribe
//
//  Created by Soner Yuksel on 20/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import CryptoKit

/// Protocol defining WireGuard IP generation capability
protocol WireguardIPManager {
    /// Generates a deterministic IP address from a public key and CIDR block
    /// - Parameters:
    ///   - publicKeyBase64: Base64-encoded WireGuard public key
    ///   - cidr: CIDR notation string (e.g., "100.64.0.0/10")
    /// - Returns: Generated IP address string
    /// - Throws: WireguardIPError if inputs are invalid
    func generateIP(publicKeyBase64: String, cidr: String) throws -> String

    /// Determines the IPv6 LAN IP for a WireGuard connection within the configured
    /// CIDR prefix (defaults to `fd54:0004::/64`).
    ///
    /// The allocation is deterministic based on the WireGuard public key:
    /// - SHA-256 hash of the public key is computed
    /// - First 8 bytes of the hash are used as the interface identifier (last 64 bits)
    /// - This provides 2^64 possible unique /128 addresses within the /64 prefix
    /// - Same public key always gets the same IPv6 address
    /// - Different public keys have negligible collision probability
    ///
    /// Returns a single IPv6 address (without `/128` suffix) that represents a /128 allocation.
    ///
    /// - Parameters:
    ///   - publicKeyBase64: Base64-encoded WireGuard public key.
    ///   - cidr: IPv6 CIDR notation string (e.g., `"fd54:0004::/64"`).
    /// - Returns: IPv6 address string (without `/128` suffix).
    /// - Throws: `InvalidArgumentError` if inputs are invalid or prefix length > 64.
    func generateIPv6(publicKeyBase64: String, cidr: String) throws -> String
}

/// Errors that can occur during IP generation
enum WireguardIPError: Error, LocalizedError {
    case invalidCIDR(String)
    case invalidBase64(String)
    case invalidIPFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidCIDR(let message):
            return "Invalid CIDR format: \(message)"
        case .invalidBase64(let message):
            return "Invalid Base64 public key: \(message)"
        case .invalidIPFormat(let message):
            return "Invalid IP format: \(message)"
        }
    }
}

/// Represents a parsed CIDR block with network address and prefix length
struct CIDRBlock {
    let networkAddress: UInt32
    let prefixLength: Int

    /// Number of bits available for host addresses
    var hostBits: Int {
        return 32 - prefixLength
    }

    /// Mask for extracting host portion of IP address
    var hostMask: UInt32 {
        return hostBits == 32 ? UInt32.max : (1 << hostBits) - 1
    }

    /// Mask for extracting network portion of IP address
    var networkMask: UInt32 {
        return ~hostMask
    }
}

/// Implementation of WireGuard IP generation using SHA-256 hashing
class WireguardIPManagerImpl: WireguardIPManager {
    private let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    func generateIP(publicKeyBase64: String, cidr: String) throws -> String {
        let cidrBlock = try parseCIDR(cidr)
        let hashValue = try hashPublicKey(publicKeyBase64)
        let ipInt = generateIPFromHash(cidrBlock, hashValue: hashValue)
        return ipIntToString(ipInt)
    }

    // MARK: - CIDR Parsing

    /// Parses CIDR notation string into CIDRBlock
    private func parseCIDR(_ cidr: String) throws -> CIDRBlock {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2 else {
            throw WireguardIPError.invalidCIDR("Invalid CIDR format: \(cidr)")
        }

        let baseIp = String(parts[0])
        guard let prefixLen = Int(parts[1]), (0...32).contains(prefixLen) else {
            throw WireguardIPError.invalidCIDR("Invalid prefix length in \(cidr)")
        }

        let networkAddress = try ipStringToInt(baseIp)
        return CIDRBlock(networkAddress: networkAddress, prefixLength: prefixLen)
    }

    /// Converts IP address string to 32-bit integer
    private func ipStringToInt(_ ip: String) throws -> UInt32 {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else {
            throw WireguardIPError.invalidIPFormat("Invalid IP format: \(ip)")
        }

        var result: UInt32 = 0

        for (index, part) in parts.enumerated() {
            guard let value = UInt8(part) else {
                throw WireguardIPError.invalidIPFormat("Invalid IP octet: \(part)")
            }
            result |= UInt32(value) << (8 * (3 - index))
        }

        return result
    }

    /// Converts 32-bit integer to IP address string
    private func ipIntToString(_ ip: UInt32) -> String {
        let o1 = (ip >> 24) & 0xFF
        let o2 = (ip >> 16) & 0xFF
        let o3 = (ip >> 8) & 0xFF
        let o4 = ip & 0xFF
        return "\(o1).\(o2).\(o3).\(o4)"
    }

    // MARK: - Hashing

    /// Hashes a Base64-encoded WireGuard public key using SHA-256
    /// Returns first 4 bytes of hash as UInt32
    private func hashPublicKey(_ base64Key: String) throws -> UInt32 {
        guard let data = Data(base64Encoded: base64Key) else {
            throw WireguardIPError.invalidBase64("Invalid Base64 public key")
        }

        let digest = SHA256.hash(data: data)
        let bytes = Array(digest)

        let value =
            (UInt32(bytes[0]) << 24) |
            (UInt32(bytes[1]) << 16) |
            (UInt32(bytes[2]) << 8)  |
            UInt32(bytes[3])

        return value
    }

    // MARK: - IP Generation

    /// Generates an IP address within a CIDR block based on a hash value
    /// Network portion comes from CIDR, host portion comes from hash
    private func generateIPFromHash(_ cidrBlock: CIDRBlock, hashValue: UInt32) -> UInt32 {
        return (cidrBlock.networkAddress & cidrBlock.networkMask) |
               (hashValue & cidrBlock.hostMask)
    }

    // Ported from Kotlin implementation
    func generateIPv6(publicKeyBase64: String, cidr: String) throws -> String {
        // Parse the IPv6 CIDR prefix
        let parts = cidr.split(separator: "/")
        guard parts.count == 2 else {
            throw WireguardIPError.invalidCIDR("Invalid IPv6 CIDR format: \(cidr)")
        }

        let prefixAddr = String(parts[0])
        guard let prefixLength = Int(parts[1]) else {
            throw WireguardIPError.invalidCIDR("Invalid prefix length in IPv6 CIDR: \(cidr)")
        }

        guard (0...128).contains(prefixLength) else {
            throw WireguardIPError.invalidCIDR("Invalid IPv6 prefix length: \(prefixLength) (must be 0-128)")
        }

        guard prefixLength <= 64 else {
            throw WireguardIPError.invalidCIDR(
                "WireGuard LAN prefix \(cidr) must be /64 or larger (smaller prefix length) to support unique /128 allocations"
            )
        }

        // Decode the base64 public key
        guard let publicKeyData = Data(base64Encoded: publicKeyBase64) else {
            throw WireguardIPError.invalidBase64("Failed to decode base64 public key: \(publicKeyBase64)")
        }

        // Generate SHA-256 hash of the decoded public key
        let hash = SHA256.hash(data: publicKeyData)
        let hashBytes = Array(hash)

        // Extract first 8 bytes for the interface identifier
        let interfaceId = Array(hashBytes[0..<8])

        // Parse the prefix address to binary representation
        var addr = in6_addr()
        guard inet_pton(AF_INET6, prefixAddr, &addr) == 1 else {
            throw WireguardIPError.invalidIPFormat("Failed to parse IPv6 address: \(prefixAddr)")
        }

        // Get the 16 bytes of the prefix address
        var ipBytes = withUnsafeBytes(of: &addr) { Array($0) }
        guard ipBytes.count == 16 else {
            throw WireguardIPError.invalidIPFormat("Invalid IPv6 address: \(prefixAddr)")
        }

        // Set the interface identifier (last 64 bits / bytes 8-15) from the hash
        for i in 0..<8 {
            ipBytes[8 + i] = interfaceId[i]
        }

        // Convert back to a human-readable IPv6 address
        var result = ipBytes.withUnsafeBufferPointer { buffer -> in6_addr in
            buffer.baseAddress!.withMemoryRebound(to: in6_addr.self, capacity: 1) { $0.pointee }
        }

        var outputBuffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        guard let cString = inet_ntop(AF_INET6, &result, &outputBuffer, socklen_t(INET6_ADDRSTRLEN)) else {
            throw WireguardIPError.invalidIPFormat("Failed to format IPv6 address")
        }

        return String(cString: cString)
    }
}
