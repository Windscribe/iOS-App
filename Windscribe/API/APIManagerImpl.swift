//
//  APIManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

class APIManagerImpl: APIManager {
    var api: WSNetServerAPIType
    var bridgeApi: WSNetBridgeAPIType
    private let logger: FileLogger
    let apiUtil: APIUtilService
    let preferences: Preferences
    let deviceAttesting: any DeviceAttesting
    var userSessionRepository: UserSessionRepository?

    init(api: WSNetServerAPIType,
         bridgeApi: WSNetBridgeAPIType,
         logger: FileLogger,
         apiUtil: APIUtilService,
         preferences: Preferences,
         deviceAttesting: any DeviceAttesting) {
        self.api = api
        self.bridgeApi = bridgeApi
        self.logger = logger
        self.apiUtil = apiUtil
        self.preferences = preferences
        self.deviceAttesting = deviceAttesting
    }
}
