//
//  APIParameters.swift
//  Windscribe
//
//  Created by Thomas on 16/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

enum APIParameters {
    static let data = "data"
    static let errorCode = "errorCode"
    static let clientAuthHash = "client_auth_hash"
    static let time = "time"
    static let token = "token"
    static let username = "username"
    static let password = "password"
    static let twoFactorCode = "2fa_code"
    static let email = "email"
    static let referralUsername = "referringUsername"
    static let currentPassword = "current_password"
    static let sessionTypeId = "session_type_id"
    static let sessionAuthHash = "session_auth_hash"
    static let credentialType = "type"
    static let logFile = "logfile"
    static let alc = "alc"
    static let deviceId = "device_id"
    static let os = "os"
    static let platform = "platform"
    static let version = "version"
    static let mobilePlanType = "mobile_plan_type"
    static let resendConfirmation = "resend_confirmation"
    static let appleID = "apple_id"
    static let claimAccount = "claim_account"
    static let tempSession = "temp_session"
    static let countryOverride = "country_override"
    static let wgForceInit = "force_init"
    static let wgPublicKey = "wg_pubkey"
    static let wgHostname = "hostname"
    static let wgTtl = "wg_ttl"

    enum IAP {
        static let appleID = "apple_id"
        static let appleSIG = "apple_sig"
        static let appleData = "apple_data"
    }

    enum Errors {
        static let errorCode = "errorCode"
        static let errorDescription = "errorDescription"
        static let errorMessage = "errorMessage"
    }

    static let emailForced = "email_forced"
    static let score = "score"
    static let sig = "sig"
    static let supportName = "support_name"
    static let supportEmail = "support_email"
    static let supportSubject = "support_subject"
    static let supportCategory = "support_category"
    static let supportMessage = "support_message"
    static let promoCode = "promo_code"
    static let payID = "pay_cpid"
    static let pcpid = "pcpid"
}

enum APIParameterValues {
    static let mobileSessionType = "4"
    static let os = "os"
    static let platform = "ios"
    static let version = "3"
    static let mobilePlanType = "apple"
    static let resendConfirmation = "1"
    static let emailForced = "1"
    static let billingVersion: Int32 = 3
    static let openVPNVersion = "2.4.6"
    static let portMapVersion = 5
    static let forceProtocols = ["wstunnel"]
}
