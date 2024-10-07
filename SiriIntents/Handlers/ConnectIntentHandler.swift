////
////  ConnectIntentHandler.swift
////  SiriIntents
////
////  Created by Andre Fonseca on 25/09/2024.
////  Copyright © 2024 Windscribe. All rights reserved.
////
//
//import Foundation
//import NetworkExtension
//import Swinject
//
//class ConnectIntentHandler: NSObject, ConnectIntentHandling {
//    // MARK: Dependencies
//    private lazy var container: Container = {
//        self.container = Container(isExt: true)
//        container.injectCore()
//        return container
//    }()
//
//    private lazy var vpnManager: VPNManager = {
//        return container.resolve(VPNManager.self)!
//    }()
//
//    func handle(intent: ConnectIntent, completion: @escaping (ConnectIntentResponse) -> Void) {
//        self.vpnManager.setup {
//            self.vpnManager.connect {
//                if $0 {
//                    completion(ConnectIntentResponse(code: .success, userActivity: nil))
//                } else {
//                    completion(ConnectIntentResponse(code: .failure, userActivity: nil))
//                }
//            }
//        }
//    }
//}
//
//class DisconnectIntentHandler: NSObject, DisconnectIntentHandling {
//    // MARK: Dependencies
//    private lazy var container: Container = {
//        self.container = Container(isExt: true)
//        container.injectCore()
//        return container
//    }()
//
//    private lazy var vpnManager: VPNManager = {
//        return container.resolve(VPNManager.self)!
//    }()
//
//    func handle(intent: DisconnectIntent, completion: @escaping (DisconnectIntentResponse) -> Void) {
//        self.vpnManager.setup {
//            self.vpnManager.disconnect() {
//                if $0 {
//                    completion(DisconnectIntentResponse(code: .success, userActivity: nil))
//                } else {
//                    completion(DisconnectIntentResponse(code: .failure, userActivity: nil))
//                }
//            }
//        }
//    }
//}
