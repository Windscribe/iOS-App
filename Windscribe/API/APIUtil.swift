//
//  APIUtil.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

// MARK: - API Utility Service Protocol

protocol APIUtilService {
    func makeApiCall<T: Decodable>(modalType: T.Type, apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) async throws -> T
    func mapToSuccess<T: Decodable>(json: String, modeType: T.Type) -> T?
    func mapToAPIError(error: String?) -> Errors
}

// MARK: - API Utility Service Implementation

final class APIUtilServiceImpl: APIUtilService {

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
        return try await withCheckedThrowingContinuation { continuation in
            let cancelable = apiCall { statusCode, responseData in
                if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
                    continuation.resume(throwing: wsNetError)
                } else {
                    guard let apiResult = self.mapToSuccess(json: responseData, modeType: modalType) else {
                        continuation.resume(throwing: self.mapToAPIError(error: responseData))
                        return
                    }
                    continuation.resume(returning: apiResult)
                }
            }

            // Store the cancelable for potential cancellation
            // Note: Swift's structured concurrency will handle cancellation automatically
            _ = cancelable
        }
    }
}
