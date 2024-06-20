//
//  APIManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class APIManagerImpl: APIManager {
    var api: WSNetServerAPI
    private let logger: FileLogger
    var userRepository: UserRepository?

    init(api: WSNetServerAPI, logger: FileLogger) {
        self.api = api
        self.logger = logger
    }
}
