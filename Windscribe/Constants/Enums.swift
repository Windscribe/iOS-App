//
//  Enums.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-03-08.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

enum CredentialType: String {
    case iKEv2 = "ikev2"
    case openVPN = "openvpn"
}

enum PopupType {
    case outOfData
    case banned
    case proPlanExpired
}
