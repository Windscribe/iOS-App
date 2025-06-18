//
//  ConnectionOptions.swift
//  Windscribe
//
//  Created by Andre Fonseca on 26/06/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum ConnectionModeType {
    case auto
    case manual

    static func defaultValue() -> ConnectionModeType { ConnectionModeType(fieldValue: DefaultValues.connectionMode) }

    var titleValue: String {
        switch self {
        case .auto:
            TextsAsset.General.auto
        case .manual:
            TextsAsset.General.manual
        }
    }

    var fieldValue: String {
        switch self {
        case .auto:
            Fields.Values.auto
        case .manual:
            Fields.Values.manual
        }
    }
}

extension ConnectionModeType {
    init(fieldValue: String) {
        self = switch fieldValue {
        case Fields.Values.auto:
            .auto
        case Fields.Values.manual:
            .manual
        default:
            .auto
        }
    }

    init(titleValue: String) {
        self = switch titleValue {
        case TextsAsset.General.auto:
            .auto
        case TextsAsset.General.manual:
            .manual
        default:
            .auto
        }
    }
}

extension ConnectedDNSType {
    init(fieldValue: String) {
        self = switch fieldValue {
        case Fields.Values.auto:
            .auto
        case Fields.Values.custom:
            .custom
        default:
            .auto
        }
    }

    init(titleValue: String) {
        self = switch titleValue {
        case TextsAsset.General.auto:
            .auto
        case TextsAsset.General.custom:
            .custom
        default:
            .auto
        }
    }

    var titleValue: String {
        switch self {
        case .auto:
            TextsAsset.General.auto
        case .custom:
            TextsAsset.General.custom
        }
    }

    var fieldValue: String {
        switch self {
        case .auto:
            Fields.Values.auto
        case .custom:
            Fields.Values.custom
        }
    }
}
