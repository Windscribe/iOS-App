//
//  User.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

struct User {
    let username: String
    let isPro: Bool
    let locationHash: String
    let planType: String
    let alcList: [String]
    let allAccessPlan: Bool
    init(session: Session) {
        // Either user have pro subscription or pay per location plan.
        isPro = session.isUserPro
        username = session.username
        locationHash = session.locHash
        planType = isPro ? "1" : "0"
        alcList = Array(session.alc)
        allAccessPlan = session.isPremium
    }
}
