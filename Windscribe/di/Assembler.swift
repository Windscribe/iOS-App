//
//  Assembler.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import Realm
import RealmSwift

extension Assembler {
    static let container = Container()
    static let assembler: Assembler = {
        return Assembler([App(), Network(), Repository(), Database(), Managers(), Routers(), ViewModels(), ViewControllerModule(), Intents()], container: container)
    }()

    /**
     Resolves any previously added dependecy from assembler.
     */
    static func resolve<Service>(_ serviceType: Service.Type) -> Service {
        if let synchronizedResolver = (assembler.resolver as? Container)?.synchronize() {
            return synchronizedResolver.resolve(serviceType)!
        } else {
            return assembler.resolver.resolve(serviceType)!
        }
    }
}
