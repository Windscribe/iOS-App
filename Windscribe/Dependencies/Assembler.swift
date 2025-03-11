//
//  Assembler.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Realm
import RealmSwift
import Swinject

extension Assembler {
    static let container = Container()
    static let assembler: Assembler = .init([App(), Network(), Repository(), Database(), Managers(), Routers(), ViewModels(), ViewControllerModule()], container: container)

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
