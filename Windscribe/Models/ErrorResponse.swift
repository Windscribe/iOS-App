//
//  ErrorResponse.swift
//  Windscribe
//
//  Created by Thomas on 14/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

struct ErrorResponse: Decodable, Error {
    let errorCode: Int?
    let errorMessage: String?
    let errorDescription: String?
    let logStatus: String?
}
