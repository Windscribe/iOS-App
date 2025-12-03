//
//  IPInfoViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import RxSwift

protocol IPInfoViewModelType {
    var isBlurStaticIpAddress: Bool { get }
    var statusSubject: CurrentValueSubject<ConnectionState?, Never> { get }
    var ipAddressSubject: CurrentValueSubject<String?, Never> { get }
    var isFavouritedSubject: CurrentValueSubject<Bool, Never> { get }
    var areActionsAvailable: CurrentValueSubject<Bool, Never> { get }
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
    private let localDatabase: LocalDatabase
    private let apiManager: APIManager
    private let userSessionRepository: UserSessionRepository
    private let bridgeApiRepository: BridgeApiRepository
    private let serverRepository: ServerRepository
    private let hapticFeedbackManager: HapticFeedbackManager

    private let disposeBag = DisposeBag()

    let statusSubject = CurrentValueSubject<ConnectionState?, Never>(nil)
    let ipAddressSubject = CurrentValueSubject<String?, Never>(nil)
    let isFavouritedSubject =  CurrentValueSubject<Bool, Never>(false)
    let areActionsAvailable =  CurrentValueSubject<Bool, Never>(true)
    let actionFailedSubject = PassthroughSubject<BridgeApiPopupType, Never>()
    private var cancellables = Set<AnyCancellable>()

    var isBlurStaticIpAddress: Bool {
        return preferences.getBlurStaticIpAddress() ?? false
    }

    init(logger: FileLogger,
         ipRepository: IPRepository,
         preferences: Preferences,
         locationManager: LocationsManager,
         localDatabase: LocalDatabase,
         apiManager: APIManager,
         userSessionRepository: UserSessionRepository,
         bridgeApiRepository: BridgeApiRepository,
         serverRepository: ServerRepository,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.logger = logger
        self.preferences = preferences
        self.locationManager = locationManager
        self.ipRepository = ipRepository
        self.localDatabase = localDatabase
        self.userSessionRepository = userSessionRepository
        self.apiManager = apiManager
        self.bridgeApiRepository = bridgeApiRepository
        self.serverRepository = serverRepository
        self.hapticFeedbackManager = hapticFeedbackManager

        ipRepository.ipState
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .compactMap { state -> MyIP? in
                guard case .available(let ip) = state, !ip.isInvalidated else {
                    return nil
                }
                return ip
            }
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("IPInfoViewModel", "Unable to get ip State, error: \(error)")
                }
            }, receiveValue: { [weak self] myip in
                if !myip.isInvalidated {
                    self?.ipAddressSubject.send(myip.userIp)
                }
            })
            .store(in: &cancellables)

        let favouriteListPublisher = localDatabase.getFavouriteListObservable()
            .toPublisher(initialValue: [])
            .replaceError(with: [])
            .eraseToAnyPublisher()

        favouriteListPublisher.combineLatest(locationManager.selectedLocationUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let groupId = locationManager.getLastSelectedLocation()
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
        Task {
            if await !performRotateIp() {
                actionFailedSubject.send(.rotateIp)
            }
        }
    }

    private func isLocationPinned(groupId: String) -> Bool {
        let favourites = localDatabase.getFavouriteList()
        return favourites.first { $0.id == groupId &&  $0.pinnedIp != nil } != nil
    }

    private func getNodeIp(groupId: String) -> GroupModel? {
        guard let groupId = Int(groupId) else { return nil }
        let allGroups = serverRepository.currentGroupModels
        return allGroups.first { $0.id == groupId }
    }

    private func performPinIp() async {
        let groupId = locationManager.getLastSelectedLocation()
        if isLocationPinned(groupId: groupId) {
            localDatabase.removeFavourite(groupId: groupId)
            return
        } else {
            guard let pinnedIp = ipAddressSubject.value else { return }
            do {
                _ = try await apiManager.pinIp(ip: pinnedIp)
                logger.logI("IPInfoViewModel", "Pin IP request successful")
                let nodeIp = preferences.getLastNodeIP()
                localDatabase.saveFavourite(favourite: Favourite(id: groupId, pinnedIp: pinnedIp, pinnedNodeIp: nodeIp))
                    .disposed(by: disposeBag)
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
                try await ipRepository.getIp().value
                guard let newIp = ipRepository.currentIp.value else {
                    logger.logE("IPInfoViewModel", "Could not get ip after rotation")
                    return false
                }
                if newIp != currentIp && !newIp.contains("--") {
                    logger.logI("IPInfoViewModel", "IP changed from \(currentIp) to \(newIp)")
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
