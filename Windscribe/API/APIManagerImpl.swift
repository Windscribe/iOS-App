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
    var bridgeApi: WSNetBridgeAPI
    private let logger: FileLogger
    let apiUtil: APIUtilService
    var userSessionRepository: UserSessionRepository?

    init(api: WSNetServerAPI,
         bridgeApi: WSNetBridgeAPI,
         logger: FileLogger,
         apiUtil: APIUtilService) {
        self.api = api
        self.bridgeApi = bridgeApi
        self.logger = logger
        self.apiUtil = apiUtil
    }
}
