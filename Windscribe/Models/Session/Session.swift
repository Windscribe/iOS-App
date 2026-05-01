//
//  Session.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-30.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct DataLeftModel {
    let unit: String
    let dataLeft: String
    let percentage: CGFloat
    let isPro: Bool
}

@available(*, deprecated, message: "Use SessionModel instead")
@objcMembers class Session: Object {
    dynamic var session: String = "session"
    dynamic var sessionAuthHash: String = ""
    dynamic var username: String = ""
    dynamic var userId: String = ""
    dynamic var trafficUsed: Double = 0
    dynamic var trafficMax: Double = 0
    dynamic var status: Int = 0
    dynamic var email: String = ""
    dynamic var emailStatus: Bool = false
    dynamic var billingPlanId: Int = 0
    dynamic var isPremium: Bool = false
    dynamic var premiumExpiryDate: String = ""
    dynamic var regDate: Int = 0
    dynamic var lastReset: String = ""
    dynamic var locRev: Int = 0
    dynamic var locHash: String = ""
    dynamic var amneziawgConfigId: String = ""

    var alc = List<String>()
    var sipCount = List<SipCount>()

    override static func primaryKey() -> String? {
        return "session"
    }

    func getModel() -> SessionModel {
        .init(from: self)
    }
}

@available(*, deprecated, message: "Don't use, it should not be necessary anywhere")
class OldSession: Session {
}

@available(*, deprecated, message: "Don't use, it should not be necessary anywhere")
@objcMembers class SipCount: Object {
    dynamic var countNumber: Int = 0
}

struct SipCountModel: Codable, Equatable {
    var countNumber: Int = 0

    enum CodingKeys: String, CodingKey {
        case countNumber = "count"
    }

    init(countNumber: Int) {
        self.countNumber = countNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countNumber = try container.decodeIfPresent(Int.self, forKey: .countNumber) ?? 0
    }
}

struct ServerInventoryModel: Codable, Equatable {
    let action: String
    let enabled: [ServerMachineModel]
    let disabled: [DisabledServerModel]
    let revision: Int64
    let backup: Int
    let amneziawgConfigId: String

    var hasBakcup: Bool { backup == 1 }

    enum CodingKeys: String, CodingKey {
        case action
        case enabled
        case disabled
        case revision
        case backup
        case amneziawgConfigId = "amneziawg_config_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decodeIfPresent(String.self, forKey: .action) ?? ""
        enabled = try container.decodeIfPresent([ServerMachineModel].self, forKey: .enabled) ?? []
        disabled = try container.decodeIfPresent([DisabledServerModel].self, forKey: .disabled) ?? []
        revision = try container.decodeIfPresent(Int64.self, forKey: .revision) ?? 0
        backup = (try? container.decodeIfPresent(Int.self, forKey: .backup)) ?? 0
        amneziawgConfigId = try container.decodeIfPresent(String.self, forKey: .amneziawgConfigId) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(disabled, forKey: .disabled)
        try container.encode(revision, forKey: .revision)
        try container.encode(backup, forKey: .backup)
        try container.encode(amneziawgConfigId, forKey: .amneziawgConfigId)
    }

    init(amneziawgConfigId: String) {
        action = ""
        enabled = []
        disabled = []
        revision = 0
        backup = 1
        self.amneziawgConfigId = amneziawgConfigId
    }
}

struct SessionModel: Codable, Equatable {
    var sessionAuthHash: String
    let username: String
    let userId: String
    let trafficUsed: Double
    let trafficMax: Double
    let status: Int
    let email: String
    let emailStatus: Bool
    let billingPlanId: Int
    let isPremium: Bool
    let premiumExpiryDate: String
    let regDate: Int
    let lastReset: String
    let locRev: Int
    let locHash: String

    let alc: [String]
    let sipCount: [SipCountModel]

    let inventory: ServerInventoryModel?

    var planType: String = "0"

    var isUserPro: Bool {
        return isPremium || isUserUnlimited
    }

    var isUserUnlimited: Bool {
        return billingPlanId == -9
    }

    var isUserCustom: Bool {
        return !isUserPro && !alc.isEmpty
    }

    var hasUserAddedEmail: Bool {
        return email != ""
    }

    var userNeedsToConfirmEmail: Bool {
        if emailStatus == false && (email != "") {
            return true
        }
        return false
    }

    var isUserGhost: Bool {
        return username == ""
    }

    var isHashAuth: Bool {
        username.hasPrefix("0x") && username.count == 34
    }

    var isEnabled: Bool {
        status == 1
    }

    var isOutOfData: Bool {
        status == 2
    }

    var isBanned: Bool {
        status == 3
    }

    enum CodingKeys: String, CodingKey {
        case data
        case sessionAuthHash = "session_auth_hash"
        case username
        case userId = "user_id"
        case trafficUsed = "traffic_used"
        case trafficMax = "traffic_max"
        case status
        case email
        case emailStatus = "email_status"
        case billingPlanId = "billing_plan_id"
        case isPremium = "is_premium"
        case premiumExpiryDate = "premium_expiry_date"
        case regDate = "reg_date"
        case lastReset = "last_reset"
        case locRev = "loc_rev"
        case locHash = "loc_hash"
        case alc
        case sip
        case inventory = "server_inventory"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        sessionAuthHash = try data.decodeIfPresent(String.self, forKey: .sessionAuthHash) ?? ""
        username = try data.decodeIfPresent(String.self, forKey: .username) ?? ""
        userId = try data.decodeIfPresent(String.self, forKey: .userId) ?? ""
        trafficUsed = try data.decodeIfPresent(Double.self, forKey: .trafficUsed) ?? 0.0
        trafficMax = try data.decodeIfPresent(Double.self, forKey: .trafficMax) ?? 0.0
        status = try data.decodeIfPresent(Int.self, forKey: .status) ?? 0
        email = try data.decodeIfPresent(String.self, forKey: .email) ?? ""
        emailStatus = try data.decodeIfPresent(Int.self, forKey: .emailStatus) == 1 ? true : false
        billingPlanId = try data.decodeIfPresent(Int.self, forKey: .billingPlanId) ?? 0
        isPremium = try data.decodeIfPresent(Int.self, forKey: .isPremium) == 1 ? true : false
        premiumExpiryDate = try data.decodeIfPresent(String.self, forKey: .premiumExpiryDate) ?? ""
        regDate = try data.decodeIfPresent(Int.self, forKey: .regDate) ?? 0
        lastReset = try data.decodeIfPresent(String.self, forKey: .lastReset) ?? ""
        do {
            locRev = try data.decodeIfPresent(Int.self, forKey: .locRev) ?? 0
        } catch DecodingError.typeMismatch {
            let value = try container.decodeIfPresent(Bool.self, forKey: .locRev) ?? false
            locRev = value ? 1 : 0
        }
        locHash = try data.decodeIfPresent(String.self, forKey: .locHash) ?? ""

        alc = try data.decodeIfPresent([String].self, forKey: .alc) ?? []

        if let sip = try data.decodeIfPresent(SipCountModel.self, forKey: .sip) {
            sipCount = [sip]
        } else {
            sipCount = []
        }

        inventory = try? data.decodeIfPresent(ServerInventoryModel.self, forKey: .inventory)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var data = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        try data.encode(sessionAuthHash, forKey: .sessionAuthHash)
        try data.encode(username, forKey: .username)
        try data.encode(userId, forKey: .userId)
        try data.encode(trafficUsed, forKey: .trafficUsed)
        try data.encode(trafficMax, forKey: .trafficMax)
        try data.encode(status, forKey: .status)
        try data.encode(email, forKey: .email)
        try data.encode(emailStatus ? 1 : 0, forKey: .emailStatus)
        try data.encode(billingPlanId, forKey: .billingPlanId)
        try data.encode(isPremium ? 1 : 0, forKey: .isPremium)
        try data.encode(premiumExpiryDate, forKey: .premiumExpiryDate)
        try data.encode(regDate, forKey: .regDate)
        try data.encode(lastReset, forKey: .lastReset)
        try data.encode(locRev, forKey: .locRev)
        try data.encode(locHash, forKey: .locHash)
        try data.encode(alc, forKey: .alc)
        if let firstSip = sipCount.first {
            try data.encode(firstSip, forKey: .sip)
        }
        try data.encodeIfPresent(inventory, forKey: .inventory)
    }

    init(from: Session) {
        // Auth hash is now stored in Keychain via Preferences — Realm field may be empty
        sessionAuthHash = from.sessionAuthHash
        username = from.username
        userId = from.userId
        trafficUsed = from.trafficUsed
        trafficMax = from.trafficMax
        status = from.status
        email = from.email
        emailStatus = from.emailStatus
        billingPlanId = from.billingPlanId
        isPremium = from.isPremium
        premiumExpiryDate = from.premiumExpiryDate
        regDate = from.regDate
        lastReset = from.lastReset
        locRev = from.locRev
        locHash = from.locHash

        alc = Array(from.alc)
        sipCount = Array(from.sipCount.map { SipCountModel(countNumber: $0.countNumber)})

        inventory = ServerInventoryModel(amneziawgConfigId: from.amneziawgConfigId)

        planType = isUserPro ? "1" : "0"
    }

    init(sessionAuthHash: String,
         username: String,
         userId: String,
         isUserPro: Bool,
         isPremium: Bool,
         email: String,
         emailStatus: Bool,
         billing: Int?,
         alc: [String],
         rebill: Int,
         billingPlanId: Int,
         trafficUsed: Double,
         trafficMax: Double,
         status: Int,
         expiryDate: String,
         lastReset: String?,
         regDate: String,
         deviceId: String,
         sipCount: Int,
         loc: String,
         locHash: String,
         revisionHash: String,
         amneziawgConfigId: String) {
        self.sessionAuthHash = sessionAuthHash
        self.username = username
        self.userId = userId
        self.trafficUsed = trafficUsed
        self.trafficMax = trafficMax
        self.status = status
        self.email = email
        self.emailStatus = emailStatus
        self.billingPlanId = billingPlanId
        self.isPremium = isPremium
        self.premiumExpiryDate = expiryDate
        self.regDate = Int(regDate.split(separator: "-").first ?? "0") ?? 0
        self.lastReset = lastReset ?? ""
        self.locRev = 0
        self.locHash = locHash
        self.alc = alc
        self.sipCount = [SipCountModel(countNumber: sipCount)]
        inventory = ServerInventoryModel(amneziawgConfigId: amneziawgConfigId)
    }

    func getIsPremium() -> Int {
        return isPremium ? 1 : 0
    }

    func getALCList() -> String {
        return alc.joined(separator: ",")
    }

    func getSipCount() -> Int {
        return sipCount.first?.countNumber ?? 0
    }

    // swiftlint:disable shorthand_operator
    func getDataLeft() -> String {
        var unit = "MB"
        let data = trafficMax - trafficUsed
        var dataLeft = data / 1024 / 1024
        if dataLeft > 1024 { unit = "GB"; dataLeft = dataLeft / 1024 }
        if dataLeft <= 0 {
            return "0 MB"
        }
        let dataLeftString = String(format: "%.2f", dataLeft)
        return "\(dataLeftString) " + unit
    }

    func getDataUsedInMB() -> Int {
        return Int(trafficUsed / 1024 / 1024)
    }

    func getDataMax() -> String {
        var unit = "MB"
        var maxData = trafficMax / 1024 / 1024
        if maxData > 1024 { unit = "GB"; maxData = maxData / 1024 }
        return "\(maxData) " + unit
    }

    func getDataLeftModel() -> DataLeftModel {
        let data = max(trafficMax - trafficUsed, 0.0)
        let dataLeftMB = data / 1024 / 1024
        let dataLeft = dataLeftMB > 1024 ? dataLeftMB / 1024 : dataLeftMB
        return DataLeftModel(unit: dataLeftMB > 1024 ? "GB" : "MB",
                             dataLeft: String(format: "%.2f", dataLeft),
                             percentage: CGFloat(data) / CGFloat(trafficMax) * 100,
                             isPro: isUserPro)
    }

    // swiftlint:enable shorthand_operator
    func getNextReset() -> String {
        let dateFormat = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        guard let lastResetDate = dateFormatter.date(from: lastReset), let nextResetDate = Calendar.current.date(byAdding: .month, value: 1, to: lastResetDate) else { return "" }
        return dateFormatter.string(from: nextResetDate)
    }
}
