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

@objcMembers class Session: Object, Decodable {
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

    var alc = List<String>()
    var sipCount = List<SipCount>()

    override static func primaryKey() -> String? {
        return "session"
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
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
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
        if let alcArray = try data.decodeIfPresent([String].self, forKey: .alc) {
            setALC(array: alcArray)
        }
        if let sip = try data.decodeIfPresent(SipCount.self, forKey: .sip) {
            setSip(object: sip)
        }
    }

    convenience init(sessionModel: SessionModel) {
        self.init()
        sessionAuthHash = sessionModel.sessionAuthHash
        username = sessionModel.username
        userId = sessionModel.userId
        trafficUsed = sessionModel.trafficUsed
        trafficMax = sessionModel.trafficMax
        status = sessionModel.status
        email = sessionModel.email
        emailStatus = sessionModel.emailStatus
        billingPlanId = sessionModel.billingPlanId
        isPremium = sessionModel.isPremium
        premiumExpiryDate = sessionModel.premiumExpiryDate
        regDate = sessionModel.regDate
        lastReset = sessionModel.lastReset
        locRev = sessionModel.locRev
        locHash = sessionModel.locHash
        setALC(array: sessionModel.alc)
        setSip(array: sessionModel.sipCount.map { SipCount(model: $0)})
    }

    func setALC(array: [String]) {
        alc.removeAll()
        alc.append(objectsIn: array)
    }

    func setSip(object: SipCount) {
        sipCount.removeAll()
        sipCount.append(object)
    }

    func setSip(array: [SipCount]) {
        sipCount.removeAll()
        sipCount.append(objectsIn: array)
    }
}

class OldSession: Session {
    convenience init(session: Session) {
        self.init()
        userId = session.userId
        trafficMax = session.trafficMax
        trafficUsed = session.trafficUsed
        status = session.status
        emailStatus = session.emailStatus
        billingPlanId = session.billingPlanId
        isPremium = session.isPremium
        alc = session.alc
        sipCount = session.sipCount
        locHash = session.locHash
        sessionAuthHash = session.sessionAuthHash
    }
}

@objcMembers class SipCount: Object, Decodable {
    dynamic var countNumber: Int = 0

    enum CodingKeys: String, CodingKey {
        case countNumber = "count"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countNumber = try container.decodeIfPresent(Int.self, forKey: .countNumber) ?? 0
    }

    convenience init(model: SipCountModel) {
        self.init()
        self.countNumber = model.countNumber
    }
}

struct SipCountModel: Equatable {
    var countNumber: Int = 0

    init(countNumber: Int) {
        self.countNumber = countNumber
    }
}

struct SessionModel: Equatable {
    let sessionAuthHash: String
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

    var isEnabled: Bool {
        status == 1
    }

    var isOutOfData: Bool {
        status == 2
    }

    var isBanned: Bool {
        status == 3
    }

    init(session: Session) {
        sessionAuthHash = session.sessionAuthHash
        username = session.username
        userId = session.userId
        trafficUsed = session.trafficUsed
        trafficMax = session.trafficMax
        status = session.status
        email = session.email
        emailStatus = session.emailStatus
        billingPlanId = session.billingPlanId
        isPremium = session.isPremium
        premiumExpiryDate = session.premiumExpiryDate
        regDate = session.regDate
        lastReset = session.lastReset
        locRev = session.locRev
        locHash = session.locHash

        alc = Array(session.alc)
        sipCount = Array(session.sipCount.map { SipCountModel(countNumber: $0.countNumber)})

        planType = isUserPro ? "1" : "0"
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
