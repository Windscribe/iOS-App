//
//  APIResult.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-11.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

enum APIResult<E, D> {
    case apiError(E)
    case success(D)
}
