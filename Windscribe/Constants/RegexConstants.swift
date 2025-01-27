//
//  RegexConstants.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum RegexConstants {
    static let urlHttpsRegex = #"https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"#
    static let urlTlsRegex = #"[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{2,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"#
}
