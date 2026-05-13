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
    var serverList: CurrentValueSubject<[ServerMachineModel], Never> { get }
    var locationsList: CurrentValueSubject<[LocationModel], Never> { get }
    var portMapHeadings: CurrentValueSubject<[String]?, Never> { get }
    var favouriteList: CurrentValueSubject<[FavoriteDatacenterlModel]?, Never> { get }
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
    var favouriteDatacenters: CurrentValueSubject<[DatacenterModel], Never> { get }

    var showNetworkSecurityTrigger: PassthroughSubject<Void, Never> { get }
    var showNotificationsTrigger: PassthroughSubject<Void, Never> { get }
    var becameActiveTrigger: PassthroughSubject<Void, Never> { get }
    var showConnectionModeTriggeer: PassthroughSubject<Void, Never> { get }
    var disconnectConnectionTrigger: PassthroughSubject<Void, Never> { get }
    var updateSSIDTrigger: PassthroughSubject<Void, Never> { get }
    var showProtocolSwitchTrigger: PassthroughSubject<Void, Never> { get }
    var showAllProtocolsFailedTrigger: PassthroughSubject<Void, Never> { get }
    var showNoInternetBeforeFailoverTrigger: PassthroughSubject<Void, Never> { get }
    var showUpdateAvailableTrigger: PassthroughSubject<CheckUpdateModel, Never> { get }
    /// Latest force-update payload, set whenever `/CheckUpdate` returns `force: true`
    /// and cleared when a subsequent response stops asserting force. The view
    /// re-presents the undismissable prompt on `applicationDidBecomeActive` while
    /// this is non-nil — handling the case where the user backgrounds without
    /// updating.
    var pendingForceUpdate: CurrentValueSubject<CheckUpdateModel?, Never> { get }

    var didShowBannedProfilePopup: Bool { get set }
    var didShowOutOfDataPopup: Bool { get set }
    var didShowProPlanExpiredPopup: Bool { get set }

    var promoPayload: CurrentValueSubject<PushNotificationPayload?, Never> { get }
    func loadLocationList()
    func sortLocationListUsingUserPreferences(ignoreStreaming: Bool, isForStreaming: Bool, locations: [LocationModel]) -> [LocationSection]
    func loadPortMap()
    func loadStaticIPLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func loadCustomConfigLatencyValues(completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
    func checkForUnreadNotifications(completion: @escaping (_ showNotifications: Bool, _ readNoticeDifferentCount: Int) -> Void)
    func saveLastNotificationTimestamp()
    func getLastNotificationTimestamp() -> Double?
    func sortFavouriteNodesUsingUserPreferences(favList: [FavoriteDatacenterlModel]) -> [FavoriteDatacenterlModel]
    func getStaticIp() -> [StaticIPModel]
    func getLatency(datacenter: DatacenterModel) -> Int
    func isPrivacyPopupAccepted() -> Bool
    func updateTrustNetworkSwitch(network: WifiNetworkModel, status: Bool)
    func getCustomConfig(customConfigID: String?) -> CustomConfigModel?

    func updatePreferred(port: String, and proto: String, for network: WifiNetworkModel) async
    func updateSSID()
    func getLocationModel(from datacenterId: Int) -> LocationModel?
    func runHapticFeedback(level: HapticFeedbackLevel)
    func checkAccountWasDowngraded() -> Bool
    func keepSessionUpdated()

    func showSimpleAlert(viewController: UIViewController?, title: String, message: String, buttonText: String)
    func showAlert(title: String, message: String, actions: [UIAlertAction])

    func getIsProDatacenterSelected() -> Bool
}
