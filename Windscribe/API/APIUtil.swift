//
//  APIUtil.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

func mapToSuccess<T: Decodable>(json: String, modeType: T.Type) -> T? {
    if modeType is String.Type {
        return json as? T
    }
    do {
        return try JSONDecoder().decode(modeType, from: json.utf8Encoded)
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

// MARK: - Async/Await API Call Method
func makeApiCallAsync<T: Decodable>(modalType: T.Type,
                                    apiCall: @escaping (@escaping (Int32, String) -> Void)
                                    -> WSNetCancelableCallback?) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
        let cancelable = apiCall { statusCode, responseData in
            if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
                continuation.resume(throwing: wsNetError)
            } else {
                guard let apiResult = mapToSuccess(json: responseData, modeType: modalType) else {
                    continuation.resume(throwing: mapToAPIError(error: responseData))
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

// MARK: - Bridge Method (Async to RxSwift)

func makeApiCall<T: Decodable>(modalType: T.Type,
                               apiCall: @escaping (@escaping (Int32, String) -> Void)
                               -> WSNetCancelableCallback?) -> Single<T> {
    return Single.create { single in
        let task = Task {
            do {
                let result = try await makeApiCallAsync(modalType: modalType, apiCall: apiCall)
                single(.success(result))
            } catch {
                single(.failure(error))
            }
        }

        return Disposables.create {
            task.cancel()
        }
    }
}

// MARK: - Legacy RxSwift Single Method (Deprecated)

@available(*, deprecated, message: "Use async makeApiCall instead")
func makeApiCallLegacy<T: Decodable>(modalType _: T.Type,
                                     apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback?) -> Single<T> {
    return Single<T>.create { callback in
        let cancelable = apiCall { statusCode, responseData in
            if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
                callback(.failure(wsNetError))
            } else {
                guard let apiResult = mapToSuccess(json: responseData, modeType: T.self) else {
                    return callback(.failure(mapToAPIError(error: responseData)))
                }
                callback(.success(apiResult))
            }
        }
        return Disposables.create {
            cancelable?.cancel()
        }
    }
}
