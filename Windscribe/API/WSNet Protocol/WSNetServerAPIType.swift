//
//  WSNetServerAPIType.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-07.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Swift-side surface of `WSNetServerAPI`. Mirrors the Obj-C bridge methods
/// the codebase actually consumes; the concrete `WSNetServerAPI` class
/// satisfies this via empty extension. Tests substitute their own mocks.
protocol WSNetServerAPIType {
    // MARK: Session

    func session(_ authHash: String,
                 appleId: String,
                 gpDeviceId: String,
                 invRev: Int64,
                 backup: Int32,
                 callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func webSession(_ authHash: String,
                    callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func deleteSession(_ authHash: String,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback

    // MARK: Account

    // swiftlint:disable function_parameter_count
    func login(_ username: String,
               password: String,
               code2fa: String,
               secureToken: String,
               captchaSolution: String,
               captchaTrailX: [NSNumber],
               captchaTrailY: [NSNumber],
               callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func signup(_ username: String,
                password: String,
                referringUsername: String,
                email: String,
                voucherCode: String,
                secureToken: String,
                captchaSolution: String,
                captchaTrailX: [NSNumber],
                captchaTrailY: [NSNumber],
                attestationToken: String,
                callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    // swiftlint:enable function_parameter_count
    func signup(usingToken token: String,
                attestationToken: String,
                callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func sso(_ provider: String,
             token: String,
             attestationToken: String,
             callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func authTokenLogin(_ username: String,
                        useAsciiCaptcha: Bool,
                        callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func authTokenSignup(_ username: String,
                         useAsciiCaptcha: Bool,
                         callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func regToken(_ callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func passwordRecovery(_ email: String,
                          callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func addEmail(_ authHash: String,
                  email: String,
                  callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func confirmEmail(_ authHash: String,
                      callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func claimAccount(_ authHash: String,
                      username: String,
                      password: String,
                      email: String,
                      voucherCode: String,
                      claimAccount: String,
                      callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func cancelAccount(_ authHash: String,
                       password: String,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func generateRandomUsername(_ callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func generateRandomPassword(_ callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func getXpressLoginCode(_ callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func verifyXpressLoginCode(_ xpressCode: String,
                               sig: String,
                               callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func verifyTvLoginCode(_ authHash: String,
                           xpressCode: String,
                           callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func claimVoucherCode(_ authHash: String,
                          voucherCode: String,
                          callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback

    // MARK: VPN

    func getLocations(_ authHash: String,
                      callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func getServers(_ authHash: String,
                    backup: Int32,
                    callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func staticIps(_ authHash: String,
                   version: UInt32,
                   callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func serverConfigs(_ authHash: String,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func serverCredentials(_ authHash: String,
                           isOpenVpnProtocol: Bool,
                           callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func portMap(_ authHash: String,
                 version: UInt32,
                 forceProtocols: [String],
                 callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func wgConfigsInit(_ authHash: String,
                       clientPublicKey: String,
                       deleteOldestKey: Bool,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func amneziawgUnblockParams(_ authHash: String,
                                callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback

    // MARK: Robert

    func getRobertFilters(_ authHash: String,
                          callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func setRobertFilter(_ authHash: String,
                         id: String,
                         status: Int32,
                         callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func syncRobert(_ authHash: String,
                    callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback

    // MARK: Billing

    func postBillingCpid(_ authHash: String,
                         payCpid: String,
                         callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func mobileBillingPlans(_ authHash: String,
                            mobilePlanType: String,
                            promo: String,
                            version: Int32,
                            callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func sendPayment(_ authHash: String,
                     appleID: String,
                     appleData: String,
                     appleSIG: String,
                     callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback

    // MARK: Other

    // swiftlint:disable function_parameter_count
    func checkUpdate(_ updateChannel: Int32,
                     appVersion: String,
                     appBuild: String,
                     osVersion: String,
                     osBuild: String,
                     callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    // swiftlint:enable function_parameter_count
    func debugLog(_ username: String,
                  strLog: String,
                  callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func pingTest(_ timeoutMs: UInt32,
                  callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func myIP(_ callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func notifications(_ authHash: String,
                       pcpid: String,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func recordInstall(_ isDesktop: Bool,
                       callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    // swiftlint:disable function_parameter_count
    func sendSupportTicket(_ supportEmail: String,
                           supportName: String,
                           supportSubject: String,
                           supportMessage: String,
                           supportCategory: String,
                           type: String,
                           channel: String,
                           callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    // swiftlint:enable function_parameter_count
    func shakeData(_ authHash: String,
                   callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
    func recordShake(forDataScore authHash: String,
                     score: String,
                     signature: String,
                     callback: @escaping (Int32, String) -> Void) -> WSNetCancelableCallback
}

extension WSNetServerAPI: WSNetServerAPIType {}
