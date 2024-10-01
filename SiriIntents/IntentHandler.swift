//
//  IntentHandler.swift
//  SiriIntents
//
//  Created by Yalcin on 2019-07-16.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Intents
import NetworkExtension
import Swinject

class IntentHandler: INExtension {
    let showLocationHandler = ShowLocationIntentHandler()
    let connectIntentHandler = ConnectIntentHandler()
    let disconnectIntentHandler = DisconnectIntentHandler()

    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is ShowLocationIntent:
            return showLocationHandler
        case is ConnectIntent:
            return connectIntentHandler
        case is DisconnectIntent:
            return disconnectIntentHandler
        default:
            return self
        }
    }
}
