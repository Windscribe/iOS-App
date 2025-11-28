//
//  MainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import StoreKit

protocol MainViewModel {
    var serverList: BehaviorSubject<[ServerModel]> { get }
    var lastConnection: BehaviorSubject<VPNConnection?> { get }
    var portMapHeadings: BehaviorSubject<[String]?> { get }
    var favouriteList: BehaviorSubject<[FavouriteGroupModel]?> { get }
    var staticIPs: BehaviorSubject<[StaticIP]?> { get }
    var customConfigs: BehaviorSubject<[CustomConfig]?> { get }
    var oldSession: OldSession? { get }
    var locationOrderBy: BehaviorSubject<String> { get }
    var latencies: BehaviorSubject<[PingData]> { get }
    var notices: CurrentValueSubject<[Notice], Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var selectedProtocol: BehaviorSubject<String> { get }
    var selectedPort: BehaviorSubject<String> { get }
    var connectionMode: BehaviorSubject<String> { get }
    var appNetwork: BehaviorSubject<AppNetwork> { get }
    var wifiNetwork: BehaviorSubject<WifiNetwork?> { get }
    var session: BehaviorSubject<Session?> { get }
    var favouriteGroups: BehaviorSubject<[GroupModel]> { get }

    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }
    var updateSSIDTrigger: PublishSubject<Void> { get }
    var showProtocolSwitchTrigger: PublishSubject<Void> { get }
    var showAllProtocolsFailedTrigger: PublishSubject<Void> { get }
    var showNoInternetBeforeFailoverTrigger: PublishSubject<Void> { get }

    var didShowBannedProfilePopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var didShowProPlanExpiredPopup: Bool { get set }

    var promoPayload: BehaviorSubject<PushNotificationPayload?> { get }
    func loadServerList()
    func sortServerListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void)
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func sortFavouriteNodesUsingUserPreferences(favList: [FavouriteGroupModel]) -> [FavouriteGroupModel]
    func getStaticIp() -> [StaticIP]
    func getLatency(ip: String?) -> Int
    func isPrivacyPopupAccepted() -> Bool
    func updatePreferredProtocolSwitch(network: WifiNetwork, preferredProtocolStatus: Bool)
    func updateTrustNetworkSwitch(network: WifiNetwork, status: Bool)
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func updatePreferred(port: String, and proto: String, for network: WifiNetwork) async
    func updateSSID()
    func getServerModel(from groupId: Int) -> ServerModel?
    func runHapticFeedback(level: HapticFeedbackLevel)
    func checkAccountWasDowngraded(for serverList: [ServerModel]) -> Bool
    func keepSessionUpdated()
}
