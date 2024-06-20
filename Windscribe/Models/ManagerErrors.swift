//
//  ManagerErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-05-28.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
enum ManagerErrors: Error, CustomStringConvertible, Equatable {
    case nonodeselected
    case norandomnodefound
    case missingipinnode
    var description: String {
        switch self {
        case .nonodeselected:
            return "No node is selected currently."
        case .norandomnodefound:
            return "No random node found."
        case .missingipinnode:
            return "Missing IP in node."
        }
    }
}
