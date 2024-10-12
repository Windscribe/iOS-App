//
//  ContainerResolver.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class ContainerResolver: ContainerResolvertype {
    func getPreferences() -> Preferences {
        return Assembler.resolve(Preferences.self)
    }

    func getLogger() -> FileLogger {
        return Assembler.resolve(FileLogger.self)
    }
}
