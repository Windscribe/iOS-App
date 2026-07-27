//
//  APIUtil.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

// MARK: - API Utility Service Protocol

protocol PromptPresenter {
    func askUser(message: String, title: String) async -> Bool
}

protocol APIUtilService {
    var ignoreSslErrorsEnabledForRuntime: Bool { get }

    func makeApiCall<T: Decodable>(modalType: T.Type, apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> T
    func makeApiCall<T: Decodable>(modalType: T.Type,
                                   maxRetries: Int,
                                   apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> T
    func mapToSuccess<T: Decodable>(json: String, modeType: T.Type) -> T?
    func mapToAPIError(error: String?) -> Errors

    func checkBridgeResult(statusCode: Int32, message: String) throws -> Bool
}

// MARK: - API Utility Service Implementation

final class APIUtilServiceImpl: APIUtilService {
    private let serverAPI: WSNetServerAPIType?
    private let bridgeAPI: WSNetBridgeAPIType?
    private let promptPresenter: PromptPresenter?
    private let sslErrorStateLock = NSLock()
    private var isIgnoreSslErrorsEnabledForRuntime = false
    private var askedToIgnoreSslErrorsForRuntime = false

    var ignoreSslErrorsEnabledForRuntime: Bool {
        sslErrorStateLock.lock()
        defer { sslErrorStateLock.unlock() }
        return isIgnoreSslErrorsEnabledForRuntime
    }

    init(serverAPI: WSNetServerAPIType? = nil,
         bridgeAPI: WSNetBridgeAPIType? = nil,
         promptPresenter: PromptPresenter? = nil) {
        self.serverAPI = serverAPI
        self.bridgeAPI = bridgeAPI
        self.promptPresenter = promptPresenter
        resetIgnoreSslErrorsForRuntime()
    }

    func mapToSuccess<T: Decodable>(json: String, modeType: T.Type) -> T? {
        if modeType is String.Type {
            return json as? T
        }
        guard let jsonData = json.utf8Encoded else {
            print("UTF-8 Encoding Error: Unable to encode string to Data")
            return nil
        }
        do {
            return try JSONDecoder().decode(modeType, from: jsonData)
        } catch {
            print("Decoding Error: \(error)")
            return nil
        }
    }

    func mapToAPIError(error: String?) -> Errors {
        if let error = error,
           let errorData = error.data(using: .utf8),
           let jsonResponse = try? JSONSerialization.jsonObject(with: errorData, options: .allowFragments),
           let data = jsonResponse as? [String: Any] {
            let apiData = APIError(data: data)
            return apiData.resolve() ?? Errors.apiError(apiData)
        }
        return Errors.parsingError
    }

    func makeApiCall<T: Decodable>(modalType: T.Type,
                                   apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> T {
        return try await makeApiCall(modalType: modalType, maxRetries: 0, apiCall: apiCall)
    }

    func makeApiCall<T: Decodable>(modalType: T.Type,
                                   maxRetries: Int,
                                   apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            var retries = maxRetries

            func attemptCall() {
                _ = apiCall { statusCode, responseData in
                    if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
                        if wsNetError == .failOverFailed, self.markSSLErrorPromptAskedIfNeeded() {
                            Task {
                                let shouldRetry = await self.shouldRetryAfterSSLErrorPrompt()
                                guard shouldRetry else {
                                    continuation.resume(throwing: wsNetError)
                                    return
                                }
                                attemptCall()
                            }
                        } else if retries <= 0 {
                            continuation.resume(throwing: wsNetError)
                        } else {
                            retries -= 1
                            attemptCall()
                        }
                    } else {
                        guard let apiResult = self.mapToSuccess(json: responseData, modeType: modalType) else {
                            continuation.resume(throwing: self.mapToAPIError(error: responseData))
                            return
                        }
                        continuation.resume(returning: apiResult)
                    }
                }
            }
            attemptCall()
        }
    }

    private func markSSLErrorPromptAskedIfNeeded() -> Bool {
        sslErrorStateLock.lock()
        defer { sslErrorStateLock.unlock() }

        guard !isIgnoreSslErrorsEnabledForRuntime,
              !askedToIgnoreSslErrorsForRuntime else { return false }

        askedToIgnoreSslErrorsForRuntime = true
        return true
    }

    private func shouldRetryAfterSSLErrorPrompt() async -> Bool {
        guard let promptPresenter = promptPresenter,
              serverAPI != nil,
              bridgeAPI != nil,
              !ignoreSslErrorsEnabledForRuntime else { return false }

        let shouldIgnoreSslErrors = await promptPresenter.askUser(
            message: TextsAsset.SSLError.message,
            title: TextsAsset.SSLError.title
        )
        guard shouldIgnoreSslErrors else { return false }

        setIgnoreSslErrorsForRuntime()
        return true
    }

    private func setIgnoreSslErrorsForRuntime() {
        sslErrorStateLock.lock()
        isIgnoreSslErrorsEnabledForRuntime = true
        sslErrorStateLock.unlock()

        serverAPI?.setIgnoreSslErrors(true)
        bridgeAPI?.setIgnoreSslErrors(true)
    }

    private func resetIgnoreSslErrorsForRuntime() {
        sslErrorStateLock.lock()
        isIgnoreSslErrorsEnabledForRuntime = false
        askedToIgnoreSslErrorsForRuntime = false
        sslErrorStateLock.unlock()

        serverAPI?.setIgnoreSslErrors(false)
        bridgeAPI?.setIgnoreSslErrors(false)
    }

    func checkBridgeResult(statusCode: Int32, message: String) throws -> Bool {
        if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
            throw wsNetError
        }
        return true
    }
}
