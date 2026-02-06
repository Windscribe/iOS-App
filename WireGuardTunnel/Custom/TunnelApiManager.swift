//
//  TunnelApiManager.swift
//  WireGuardTunnel
//
//  Created by Network Extension
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Network
import os.log

/// Manages API calls from within the tunnel extension
/// Uses URLSession to route through the tunnel instead of bypassing it
protocol TunnelApiManager {
    func getSession(sessionAuth: String) async throws -> SessionResponse
    func checkIP() async throws -> String
}

/// Response from session endpoint
struct SessionResponse: Codable {
    let data: SessionData?
    let errorCode: Int?

    var status: Int {
        return data?.status ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case data
        case errorCode = "error_code"
    }
}

struct SessionData: Codable {
    let status: Int
    let statusMessage: String?

    enum CodingKeys: String, CodingKey {
        case status
        case statusMessage = "status_message"
    }
}

class TunnelApiManagerImpl: TunnelApiManager {

    private let logger: FileLogger
    private let baseURL: String

    init(logger: FileLogger, baseURL: String = "https://api.windscribe.com") {
        self.logger = logger
        self.baseURL = baseURL
    }

    /// Makes an HTTP GET request using raw TCP connection through the tunnel
    /// This bypasses URLSession which doesn't respect tunnel routing
    private func makeHTTPSRequest(url: URL, timeout: TimeInterval = 30) async throws -> (Data, Int) {
        guard let host = url.host else {
            throw TunnelApiError.invalidURL
        }

        let port = url.port ?? 443

        // Create NWConnection with default parameters
        // In a PacketTunnelProvider, all traffic automatically routes through tunnel
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port)),
            using: .tcp
        )

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            var receivedData = Data()
            var statusCode = 0

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.logger.logI("TunnelApiManager", "Connection ready to \(host):\(port)")

                    // Build HTTP request
                    let path = url.path.isEmpty ? "/" : url.path
                    let query = url.query.map { "?\($0)" } ?? ""
                    let requestString = "GET \(path)\(query) HTTP/1.1\r\n" +
                                      "Host: \(host)\r\n" +
                                      "User-Agent: Windscribe iOS\r\n" +
                                      "Accept: */*\r\n" +
                                      "Connection: close\r\n" +
                                      "\r\n"

                    guard let requestData = requestString.data(using: .utf8) else {
                        if !hasResumed {
                            hasResumed = true
                            connection.cancel()
                            continuation.resume(throwing: TunnelApiError.invalidRequest)
                        }
                        return
                    }

                    // Send HTTP request
                    connection.send(content: requestData, completion: .contentProcessed { error in
                        if let error = error {
                            self.logger.logE("TunnelApiManager", "Send error: \(error)")
                            if !hasResumed {
                                hasResumed = true
                                connection.cancel()
                                continuation.resume(throwing: TunnelApiError.networkError(error))
                            }
                            return
                        }

                        // Receive response
                        self.receiveResponse(connection: connection, continuation: continuation)
                    })

                case .failed(let error):
                    self.logger.logE("TunnelApiManager", "Connection failed: \(error)")
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: TunnelApiError.networkError(error))
                    }

                case .cancelled:
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: TunnelApiError.networkError(NSError(domain: "Cancelled", code: -1)))
                    }

                default:
                    break
                }
            }

            connection.start(queue: .global())

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if !hasResumed {
                    hasResumed = true
                    connection.cancel()
                    continuation.resume(throwing: TunnelApiError.timeout)
                }
            }
        }
    }

    private func receiveResponse(connection: NWConnection, continuation: CheckedContinuation<(Data, Int), Error>) {
        var receivedData = Data()
        var statusCode = 0
        var hasResumed = false

        func receiveData() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                if let error = error {
                    self.logger.logE("TunnelApiManager", "Receive error: \(error)")
                    if !hasResumed {
                        hasResumed = true
                        connection.cancel()
                        continuation.resume(throwing: TunnelApiError.networkError(error))
                    }
                    return
                }

                if let data = data {
                    receivedData.append(data)
                }

                if isComplete {
                    connection.cancel()

                    // Parse HTTP response
                    if let response = String(data: receivedData, encoding: .utf8) {
                        let lines = response.components(separatedBy: "\r\n")

                        // Parse status line
                        if let statusLine = lines.first {
                            let parts = statusLine.components(separatedBy: " ")
                            if parts.count >= 2, let code = Int(parts[1]) {
                                statusCode = code
                            }
                        }

                        // Find body (after empty line)
                        if let bodyStart = response.range(of: "\r\n\r\n") {
                            let body = String(response[bodyStart.upperBound...])
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: (Data(body.utf8), statusCode))
                            }
                            return
                        }
                    }

                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: (receivedData, statusCode))
                    }
                } else {
                    // Continue receiving
                    receiveData()
                }
            }
        }

        receiveData()
    }

    /// Fetches user session to validate authentication
    /// - Parameter sessionAuth: Session authentication token
    /// - Returns: SessionResponse with user status
    func getSession(sessionAuth: String) async throws -> SessionResponse {
        let endpoint = "\(baseURL)/Session"

        guard var urlComponents = URLComponents(string: endpoint) else {
            logger.logE("TunnelApiManager", "Invalid URL: \(endpoint)")
            throw TunnelApiError.invalidURL
        }

        // Add session_auth as query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "session_auth_hash", value: sessionAuth)
        ]

        guard let url = urlComponents.url else {
            logger.logE("TunnelApiManager", "Failed to create URL with query parameters")
            throw TunnelApiError.invalidURL
        }

        logger.logI("TunnelApiManager", "Making session request through tunnel to: \(url.absoluteString)")
        os_log("PacketTunnelProvider: Making session request through tunnel to: %{public}@", log: OSLog.default, type: .info, url.absoluteString)

        let (data, statusCode) = try await makeHTTPSRequest(url: url)

        logger.logI("TunnelApiManager", "Session request completed with status: \(statusCode)")
        os_log("PacketTunnelProvider: Session request completed with status: %d", log: OSLog.default, type: .info, statusCode)

        guard statusCode == 200 else {
            logger.logE("TunnelApiManager", "HTTP error: \(statusCode)")
            throw TunnelApiError.httpError(statusCode)
        }

        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.logD("TunnelApiManager", "Response: \(responseString)")
        }

        let decoder = JSONDecoder()
        let sessionResponse = try decoder.decode(SessionResponse.self, from: data)

        logger.logI("TunnelApiManager", "Session status: \(sessionResponse.status)")
        os_log("PacketTunnelProvider: Session status: %d", log: OSLog.default, type: .info, sessionResponse.status)

        return sessionResponse
    }

    /// Checks the current IP address as seen by the server
    /// This verifies that traffic is routing through the tunnel
    /// - Returns: IP address string (e.g., "104.21.45.67")
    func checkIP() async throws -> String {
        // Use simple HTTP endpoint that returns plain text IP
        // Try multiple endpoints in case one fails
        let endpoints = [
            "http://icanhazip.com/",
            "http://ifconfig.me/ip",
            "http://api.ipify.org/"
        ]

        var lastError: Error?

        for endpoint in endpoints {
            do {
                guard let url = URL(string: endpoint) else {
                    continue
                }

                logger.logI("TunnelApiManager", "Checking IP through tunnel: \(endpoint)")
                os_log("PacketTunnelProvider: Checking IP through tunnel: %{public}@", log: OSLog.default, type: .info, endpoint)

                let (data, statusCode) = try await makeHTTPRequest(url: url, timeout: 10)

                logger.logI("TunnelApiManager", "CheckIP request completed with status: \(statusCode)")
                os_log("PacketTunnelProvider: CheckIP request completed with status: %d", log: OSLog.default, type: .info, statusCode)

                guard statusCode == 200 else {
                    logger.logE("TunnelApiManager", "CheckIP HTTP error: \(statusCode), trying next endpoint")
                    continue
                }

                guard let ipAddress = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    logger.logE("TunnelApiManager", "Failed to decode IP address, trying next endpoint")
                    os_log("PacketTunnelProvider: Failed to decode IP address, trying next endpoint", log: OSLog.default, type: .error)
                    continue
                }

                logger.logI("TunnelApiManager", "Received response: '\(ipAddress)' (length: \(ipAddress.count))")
                os_log("PacketTunnelProvider: Received response: '%{public}@' (length: %d)", log: OSLog.default, type: .info, ipAddress, ipAddress.count)

                // Validate it looks like an IPv4 address (WireGuard tunnel should provide IPv4)
                // If we're getting IPv6, it means traffic is bypassing the tunnel
                let ipv4Pattern = "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$"

                if let regex = try? NSRegularExpression(pattern: ipv4Pattern),
                   regex.firstMatch(in: ipAddress, range: NSRange(ipAddress.startIndex..., in: ipAddress)) != nil {

                    logger.logI("TunnelApiManager", "✅ IPv4 through tunnel: \(ipAddress)", flushImmediately: true)
                    os_log("PacketTunnelProvider: ✅ IPv4 through tunnel: %{public}@", log: OSLog.default, type: .info, ipAddress)

                    return ipAddress
                } else {
                    // If we get IPv6, it means traffic is likely bypassing the tunnel
                    if ipAddress.contains(":") {
                        logger.logE("TunnelApiManager", "⚠️ Got IPv6 address '\(ipAddress)' - traffic may be bypassing tunnel!", flushImmediately: true)
                        os_log("PacketTunnelProvider: ⚠️ Got IPv6 address - traffic may be bypassing tunnel!", log: OSLog.default, type: .error)
                    } else {
                        logger.logE("TunnelApiManager", "Invalid IP format: '\(ipAddress)', trying next endpoint")
                        os_log("PacketTunnelProvider: Invalid IP format: '%{public}@', trying next endpoint", log: OSLog.default, type: .error, ipAddress)
                    }
                    continue
                }

            } catch {
                logger.logE("TunnelApiManager", "CheckIP failed for \(endpoint): \(error.localizedDescription)")
                lastError = error
                continue
            }
        }

        // All endpoints failed
        logger.logE("TunnelApiManager", "All checkIP endpoints failed")
        throw lastError ?? TunnelApiError.invalidResponse
    }

    /// Makes an HTTP (not HTTPS) GET request - used for checkip endpoint
    private func makeHTTPRequest(url: URL, timeout: TimeInterval = 30) async throws -> (Data, Int) {
        guard let host = url.host else {
            throw TunnelApiError.invalidURL
        }

        let port = url.port ?? 80

        // Force IPv4 only to ensure we get the tunnel's IPv4 address
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .other  // Use the VPN tunnel interface
        parameters.prohibitExpensivePaths = false
        parameters.prohibitConstrainedPaths = false

        // Restrict to IPv4 only
        let ipOptions = NWProtocolIP.Options()
        ipOptions.version = .v4
        parameters.defaultProtocolStack.internetProtocol = ipOptions

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port)),
            using: parameters
        )

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            var receivedData = Data()
            var statusCode = 0

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.logger.logI("TunnelApiManager", "HTTP connection ready to \(host):\(port)")

                    let path = url.path.isEmpty ? "/" : url.path
                    let query = url.query.map { "?\($0)" } ?? ""
                    let requestString = "GET \(path)\(query) HTTP/1.1\r\n" +
                                      "Host: \(host)\r\n" +
                                      "User-Agent: Windscribe iOS\r\n" +
                                      "Accept: */*\r\n" +
                                      "Connection: close\r\n" +
                                      "\r\n"

                    guard let requestData = requestString.data(using: .utf8) else {
                        if !hasResumed {
                            hasResumed = true
                            connection.cancel()
                            continuation.resume(throwing: TunnelApiError.invalidRequest)
                        }
                        return
                    }

                    connection.send(content: requestData, completion: .contentProcessed { error in
                        if let error = error {
                            self.logger.logE("TunnelApiManager", "HTTP send error: \(error)")
                            if !hasResumed {
                                hasResumed = true
                                connection.cancel()
                                continuation.resume(throwing: TunnelApiError.networkError(error))
                            }
                            return
                        }

                        self.receiveResponse(connection: connection, continuation: continuation)
                    })

                case .failed(let error):
                    self.logger.logE("TunnelApiManager", "HTTP connection failed: \(error)")
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: TunnelApiError.networkError(error))
                    }

                case .cancelled:
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: TunnelApiError.networkError(NSError(domain: "Cancelled", code: -1)))
                    }

                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if !hasResumed {
                    hasResumed = true
                    connection.cancel()
                    continuation.resume(throwing: TunnelApiError.timeout)
                }
            }
        }
    }
}

/// Errors that can occur during tunnel API calls
enum TunnelApiError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequest:
            return "Invalid HTTP request"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        }
    }
}
