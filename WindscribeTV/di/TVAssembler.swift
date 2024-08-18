//
//  TVAssembler.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import Realm
import RealmSwift

extension Assembler {
    static let container = Container()
    static let assembler: Assembler = {
        return Assembler([App(), Network(), Repository(), Database(), Managers(),TVViewModels(), TVRouters(), TVViewControllers()], container: container)
    }()
    /**
     Resolves any previously added dependecy from assembler.
     */
    static func resolve<Service>(_ serviceType: Service.Type) -> Service {
        return assembler.resolver.resolve(serviceType)!
    }
}
