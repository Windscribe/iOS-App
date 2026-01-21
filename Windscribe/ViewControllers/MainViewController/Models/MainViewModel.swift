//
//  MainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine
import StoreKit

protocol MainViewModel {
    var serverList: CurrentValueSubject<[ServerModel], Never> { get }
    var portMapHeadings: CurrentValueSubject<[String]?, Never> { get }
    var favouriteList: CurrentValueSubject<[FavouriteGroupModel]?, Never> { get }
    var staticIPs: CurrentValueSubject<[StaticIPModel]?, Never> { get }
    var customConfigs: CurrentValueSubject<[CustomConfigModel], Never> { get }
    var oldSession: SessionModel? { get }
    var locationOrderBy: CurrentValueSubject<String, Never> { get }
    var latencies: CurrentValueSubject<[PingDataModel], Never> { get }
    var notices: CurrentValueSubject<[NoticeModel], Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var selectedProtocol: CurrentValueSubject<String, Never> { get }
    var selectedPort: CurrentValueSubject<String, Never> { get }
    var connectionMode: CurrentValueSubject<String, Never> { get }
    var appNetwork: CurrentValueSubject<AppNetwork, Never> { get }
    var wifiNetwork: CurrentValueSubject<WifiNetworkModel?, Never> { get }
    var sessionModel: CurrentValueSubject<SessionModel?, Never> { get }
    var favouriteGroups: CurrentValueSubject<[GroupModel], Never> { get }

    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }
    var showConnectionModeTriggeer: PassthroughSubject<Void, Never> { get }
    var disconnectConnectionTrigger: PassthroughSubject<Void, Never> { get }
    var updateSSIDTrigger: PassthroughSubject<Void, Never> { get }
    var showProtocolSwitchTrigger: PassthroughSubject<Void, Never> { get }
    var showAllProtocolsFailedTrigger: PassthroughSubject<Void, Never> { get }
    var showNoInternetBeforeFailoverTrigger: PassthroughSubject<Void, Never> { get }

    var didShowBannedProfilePopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var didShowProPlanExpiredPopup: Bool { get set }

    var promoPayload: CurrentValueSubject<PushNotificationPayload?, Never> { get }
    func loadServerList()
    func sortServerListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, servers: [ServerModel], completion: @escaping (_ result: [ServerSection]) -> Void)
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func sortFavouriteNodesUsingUserPreferences(favList: [FavouriteGroupModel]) -> [FavouriteGroupModel]
    func getStaticIp() -> [StaticIPModel]
    func getLatency(ip: String?) -> Int
    func isPrivacyPopupAccepted() -> Bool
    func updateTrustNetworkSwitch(network: WifiNetworkModel, status: Bool)
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func updatePreferred(port: String, and proto: String, for network: WifiNetworkModel) async
    func updateSSID()
    func getServerModel(from groupId: Int) -> ServerModel?
    func runHapticFeedback(level: HapticFeedbackLevel)
    func checkAccountWasDowngraded(for serverList: [ServerModel]) -> Bool
    func keepSessionUpdated()

    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String)
    func showAlert(title: String, message: String, actions: [UIAlertAction])
}
