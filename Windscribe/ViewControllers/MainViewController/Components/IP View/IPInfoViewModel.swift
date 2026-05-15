//
//  IPInfoViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine

protocol IPInfoViewModelType {
    var isBlurStaticIpAddress: Bool { get }
    var statusSubject: CurrentValueSubject<ConnectionState?, Never> { get }
    var ipAddressSubject: CurrentValueSubject<String?, Never> { get }
    var isFavouritedSubject: CurrentValueSubject<Bool, Never> { get }
    var areActionsAvailable: CurrentValueSubject<Bool, Never> { get }
    var isRotatingIpSubject: CurrentValueSubject<Bool, Never> { get }
    var actionFailedSubject: PassthroughSubject<BridgeApiPopupType, Never> { get }

    func markBlurStaticIpAddress(isBlured: Bool)
    func saveIp()
    func rotateIp()
    func runHapticFeedback(level: HapticFeedbackLevel)
}

class IPInfoViewModel: IPInfoViewModelType {
    private let logger: FileLogger
    private let preferences: Preferences
    private let ipRepository: IPRepository
    private let locationManager: LocationsManager
    private let apiManager: APIManager
    private let userSessionRepository: UserSessionRepository
    private let bridgeApiRepository: BridgeApiRepository
    private let locationListRepository: LocationListRepository
    private let hapticFeedbackManager: HapticFeedbackManager

    let statusSubject = CurrentValueSubject<ConnectionState?, Never>(nil)
    let ipAddressSubject = CurrentValueSubject<String?, Never>(nil)
    let isFavouritedSubject =  CurrentValueSubject<Bool, Never>(false)
    let areActionsAvailable =  CurrentValueSubject<Bool, Never>(true)
    let isRotatingIpSubject =  CurrentValueSubject<Bool, Never>(false)
    let actionFailedSubject = PassthroughSubject<BridgeApiPopupType, Never>()
    private var cancellables = Set<AnyCancellable>()

    var isBlurStaticIpAddress: Bool {
        return preferences.getBlurStaticIpAddress() ?? false
    }

    init(logger: FileLogger,
         ipRepository: IPRepository,
         preferences: Preferences,
         locationManager: LocationsManager,
         apiManager: APIManager,
         userSessionRepository: UserSessionRepository,
         bridgeApiRepository: BridgeApiRepository,
         locationListRepository: LocationListRepository,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.logger = logger
        self.preferences = preferences
        self.locationManager = locationManager
        self.ipRepository = ipRepository
        self.userSessionRepository = userSessionRepository
        self.apiManager = apiManager
        self.bridgeApiRepository = bridgeApiRepository
        self.locationListRepository = locationListRepository
        self.hapticFeedbackManager = hapticFeedbackManager

        ipRepository.ipState
            .receive(on: DispatchQueue.main)
            .compactMap { state -> String? in
                guard case .available(let ipAddress) = state else {
                    return nil
                }
                return ipAddress
            }
            .sink { [weak self] ipAddress in
                guard let self = self else { return }
                self.ipAddressSubject.send(ipAddress)
            }
            .store(in: &cancellables)

        locationListRepository.favouriteListSubject.combineLatest(locationManager.selectedLocationUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let groupId = locationManager.getLastConnectionTarget()
                self.isFavouritedSubject.send(isLocationPinned(groupId: groupId))
            }
            .store(in: &cancellables)

        bindBridgeApiCallback()
    }

    private func bindBridgeApiCallback() {
        bridgeApiRepository.bridgeIsAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady in
                self?.areActionsAvailable.send(isReady)
            }
            .store(in: &cancellables)
    }

    func markBlurStaticIpAddress(isBlured: Bool) {
        preferences.saveBlurStaticIpAddress(bool: isBlured)
    }

    func saveIp() {
        Task {
            await performPinIp()
        }
    }

    func rotateIp() {
        guard !isRotatingIpSubject.value else { return }
        isRotatingIpSubject.send(true)
        Task {
            if await !performRotateIp() {
                actionFailedSubject.send(.rotateIp)
            }
            try await Task.sleep(nanoseconds: 2_000_000_000)
            isRotatingIpSubject.send(false)
        }
    }

    private func isLocationPinned(groupId: String) -> Bool {
        let favourites = locationListRepository.favouriteListSubject.value
        return favourites.first { $0.id == groupId &&  $0.pinnedIp != nil } != nil
    }

    private func getServerIp(datacenterIp: Int) -> DatacenterModel? {
        locationListRepository.currentDatacenterModels
            .first { $0.id == datacenterIp }
    }

    private func performPinIp() async {
        let groupId = locationManager.getLastConnectionTarget()
        if isLocationPinned(groupId: groupId) {
            locationListRepository.removeFavorite(with: groupId)
            return
        } else {
            guard let pinnedIp = ipAddressSubject.value else { return }
            do {
                _ = try await apiManager.pinIp(ip: pinnedIp)
                logger.logI("IPInfoViewModel", "Pin IP request successful")
                let nodeIp = preferences.getLastNodeIP()
                locationListRepository.saveFavorite(for: FavouriteModel(id: groupId,
                                                                  pinnedIp: pinnedIp, pinnedNodeHostname: nodeIp))
            } catch {
                logger.logE("IPInfoViewModel", "Pin IP request failed: \(error)")
                actionFailedSubject.send(.pinIp)
            }
        }
    }

    func performRotateIp() async -> Bool {
        do {
            _ = try await apiManager.rotateIp()
            logger.logI("IPInfoViewModel", "Rotate IP request successful")
            let currentIp = ipAddressSubject.value ?? " -- "
            do {
                try await self.ipRepository.getIp()
                guard let newIp = ipRepository.currentIp.value else {
                    logger.logE("IPInfoViewModel", "Could not get ip after rotation")
                    return false
                }
                if newIp != currentIp && !newIp.contains("--") {
                    logger.logI("IPInfoViewModel", "IP changed from \(currentIp.redactedIP) to \(newIp.redactedIP)")
                    return true
                }
                logger.logI("IPInfoViewModel", "IP state did not change within timeout")
                return false
            } catch {
                logger.logE("IPInfoViewModel", "Ip update failed: \(error)")
                return false
            }
        } catch {
            logger.logE("IPInfoViewModel", "Rotate IP request failed: \(error)")
            return false
        }
    }

    func runHapticFeedback(level: HapticFeedbackLevel) {
        hapticFeedbackManager.run(level: level)
    }
}
