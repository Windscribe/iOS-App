//
//  APIManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol APIManager {
    // Session
    func getSession() -> Single<Session>
    func getWebSession() -> Single<WebSession>
    func deleteSession() -> Single<APIMessage>
    func getSession(sessionAuth: String) -> Single<Session>
    // Account
    func login(username: String, password: String, code2fa: String) -> Single<Session>
    func signup(username: String, password: String, referringUsername: String, email: String) -> Single<Session>
    func addEmail(email: String) -> Single<APIMessage>
    func confirmEmail() -> Single<APIMessage>
    func regToken() -> RxSwift.Single<Token>
    func signUpUsingToken(token: String) -> RxSwift.Single<Session>
    func claimAccount(username: String, password: String, email: String) -> RxSwift.Single<APIMessage>
    func getXpressLoginCode() -> RxSwift.Single<XPressLoginCodeResponse> 
    func verifyXPressLoginCode(code: String, sig: String) -> RxSwift.Single<XPressLoginVerifyResponse>
    // VPN
    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) -> Single<ServerList>
    func getStaticIpList() -> Single<StaticIPList>
    func getOpenVPNServerConfig(openVPNVersion: String) -> Single<String>
    func getIKEv2ServerCredentials() -> Single<IKEv2ServerCredentials>
    func getOpenVPNServerCredentials() -> Single<OpenVPNServerCredentials>
    func getPortMap(version: Int, forceProtocols: [String]) -> Single<PortMapList>
    // Billing
    func getMobileBillingPlans(promo: String?) -> Single<MobilePlanList>
    func postBillingCpID(pcpID: String) -> Single<APIMessage>
    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) -> Single<APIMessage>
    // Robert
    func getRobertFilters() -> Single<RobertFilters>
    func updateRobertSettings(id: String, status: Int32) -> Single<APIMessage>
    func syncRobertFilters() -> Single<APIMessage>
    // Other
    func recordInstall(platform: String) -> Single<APIMessage>
    func getNotifications(pcpid: String) -> Single<NoticeList>
    func getIp() -> Single<MyIP>
    func sendDebugLog(username: String, log: String) -> Single<APIMessage>
    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) -> Single<APIMessage>
    func getShakeForDataLeaderboard() -> Single<Leaderboard>
    func recordShakeForDataScore(score: Int, userID: String) -> Single<APIMessage>
}
