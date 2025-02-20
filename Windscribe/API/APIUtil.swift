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
        return nil
    }
}

func mapToAPIError(error: String?) -> Error {
    if let error = error,
       let errorData = error.data(using: .utf8),
       let jsonResponse = try? JSONSerialization.jsonObject(with: errorData, options: .allowFragments),
       let data = jsonResponse as? [String: Any] {
        let apiData = APIError(data: data)
        return apiData.resolve() ?? Errors.apiError(apiData)
    }
    return Errors.parsingError
}

func makeApiCall<T: Decodable>(modalType _: T.Type, apiCall: @escaping (@escaping (Int32, String) -> Void) -> WSNetCancelableCallback) -> Single<T> {
    return Single<T>.create { callback in
        _ = apiCall { statusCode, responseData in
            if let wsNetError = WSNetErrors(rawValue: statusCode)?.error {
                callback(.failure(wsNetError))
            } else {
                guard let apiResult = mapToSuccess(json: responseData, modeType: T.self) else {
                    return callback(.failure(mapToAPIError(error: responseData)))
                }
                callback(.success(apiResult))
            }
        }
        return Disposables.create {}
    }
}
