//
//  ContainerResolvertype.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol ContainerResolvertype {
    func getPreferences() -> Preferences
    func getLogger() -> FileLogger
    func getApi() -> WSNetServerAPI
}
