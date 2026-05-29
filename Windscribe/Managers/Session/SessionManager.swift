//
//  SessionManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine
import Swinject
import UIKit
import SwiftUI

protocol SessionManager {
    func setSessionTimer()
    func listenForSessionChanges()
    func logoutUser()
    func updateSession() async throws
    func updateSession(force: Bool) async throws
    func updateSession(_ appleID: String) async throws
    func updateSession(_ appleID: String, force: Bool) async throws
    func login(auth: String) async throws
    func updateFrom(session: SessionModel) async
    func keepSessionUpdated()
    func updateAfterLoginIn() async
    var sessionFetchInProgress: Bool { get set }
    var updateSessionTask: Task<Void, Error>? { get set }
    var checkForDiscconectReasonTrigger: PassthroughSubject<Void, Never> { get }
}

class SessionManagerImpl: SessionManager {
    var sessionNotificationToken: NotificationToken?
    var sessionTimer: Timer?
    var sessionFetchInProgress = false
    var lastCheckForServerConfig = Date()

    let  checkForDiscconectReasonTrigger = PassthroughSubject<Void, Never>()

    // Not circular dependencies
    private let wgCredentials: WgCredentials
    private let logger: FileLogger
    private let apiManager: APIManager
    private let credentialsRepo: CredentialsRepository
    private let staticIPRepo: StaticIpRepository
    private let portmapRepo: PortMapRepository
    private let preferences: Preferences
    private let latencyRepo: LatencyRepository
    private let userSessionRepository: UserSessionRepository
    private let locationsManager: LocationsManager
    private let vpnStateRepository: VPNStateRepository
    private let antiCensorshipRepository: AntiCensorshipRepository
    private let locationListRepository: LocationListRepository

    private let vpnManager: VPNManager
    private let ssoManager: SSOManaging
    private let windowProvider: WindowProvider

    private var cancellables = Set<AnyCancellable>()
    var updateSessionTask: Task<Void, Error>?

    init (wgCredentials: WgCredentials,
          logger: FileLogger,
          apiManager: APIManager,
          credentialsRepo: CredentialsRepository,
          staticIPRepo: StaticIpRepository,
          portmapRepo: PortMapRepository,
          preferences: Preferences,
          latencyRepo: LatencyRepository,
          userSessionRepository: UserSessionRepository,
          locationsManager: LocationsManager,
          vpnStateRepository: VPNStateRepository,
          vpnManager: VPNManager,
          ssoManager: SSOManaging,
          antiCensorshipRepository: AntiCensorshipRepository,
          locationListRepository: LocationListRepository,
          windowProvider: WindowProvider) {
        self.wgCredentials = wgCredentials
        self.logger = logger
        self.apiManager = apiManager
        self.credentialsRepo = credentialsRepo
        self.staticIPRepo = staticIPRepo
        self.portmapRepo = portmapRepo
        self.preferences = preferences
        self.userSessionRepository = userSessionRepository
        self.latencyRepo = latencyRepo
        self.locationsManager = locationsManager
        self.vpnStateRepository = vpnStateRepository
        self.vpnManager = vpnManager
        self.ssoManager = ssoManager
        self.antiCensorshipRepository = antiCensorshipRepository
        self.locationListRepository = locationListRepository
        self.windowProvider = windowProvider

        keepSessionUpdated()

        self.antiCensorshipRepository.selecteRoutingTypeSubject
            .dropFirst()
            .sink { [weak self] _ in
                self?.keepSessionUpdated()
            }
            .store(in: &cancellables)
    }

    func setSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.keepSessionUpdated()
        }
        NotificationCenter.default.publisher(for: Notifications.userLoggedOut)
            .sink { [weak self] _ in
                self?.cancelTimers()
            }
            .store(in: &cancellables)
    }

    func cancelTimers() {
        logger.logD("SessionManager", "Cancelled Session timer.")
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    func keepSessionUpdated() {
        // Don't create new task if update already in progress
        guard !sessionFetchInProgress else {
            logger.logD("SessionManager", "Session update already in progress, skipping keepSessionUpdated.")
            return
        }

        Task { @MainActor in
            guard userSessionRepository.sessionAuth != nil else { return }

            guard await userSessionRepository.syncSession() else {
                self.logoutUser()
                return
            }

            do {
                try await self.updateSession()
            } catch let error {
                if let errors = error as? Errors {
                    if errors == .sessionIsInvalid  || errors == .validationFailure {
                        self.logoutUser()
                    }
                } else {
                    self.logger.logE("SessionManager", "Failed to update error: \(error)")
                }
            }

            updateServerConfigs()
        }
    }

    func updateSession() async throws {
        try await updateSessionUsing(token: nil, force: false)
    }

    func updateSession(force: Bool) async throws {
        try await updateSessionUsing(token: nil, force: force)
    }

    func updateSession(_ appleID: String) async throws {
        try await updateSessionUsing(token: appleID, force: false)
    }

    func updateSession(_ appleID: String, force: Bool) async throws {
        try await updateSessionUsing(token: appleID, force: force)
    }

    @MainActor
    private func updateSessionUsing(token: String?, force: Bool = false) async throws {
        // If force update, cancel any pending task
        if force {
            logger.logI("SessionManager", "Force update requested - canceling pending tasks")
            updateSessionTask?.cancel()
            updateSessionTask = nil
            sessionFetchInProgress = false
        }

        // If update already in progress and not forced, ignore this call
        if sessionFetchInProgress && !force {
            logger.logD("SessionManager", "Session update already in progress, ignoring duplicate call. Timer will handle next update.")
            return
        }

        // Create new task
        let task = Task<Void, Error> { @MainActor in
            self.sessionFetchInProgress = true

            defer {
                self.sessionFetchInProgress = false
                self.updateSessionTask = nil
            }
            do {
                let session = try await self.apiManager.getSession(token)
                self.logger.logI("SessionManager", "Session updated for \(session.username)")
                await self.updateFrom(session: session)
            } catch {
                checkForDiscconectReasonTrigger.send(())
                throw error
            }
        }

        updateSessionTask = task

        try await task.value
    }

    func login(auth: String) async throws {
        var session = try await self.apiManager.getSession(sessionAuth: auth)
        wgCredentials.delete()
        if session.sessionAuthHash.isEmpty {
            session.sessionAuthHash = auth
        }
        Task {
            try? await locationListRepository.updateAll()
            await updateFrom(session: session)
        }
    }

    func updateAfterLoginIn() async {
        try? await locationListRepository.updateAll()
        try? await updateSession()
    }

    func updateFrom(session: SessionModel) async {
        await userSessionRepository.update(session: session)
        if antiCensorshipRepository.needsRefresh() {
            antiCensorshipRepository.refreshParams()
        }
    }

    func listenForSessionChanges() {
        userSessionRepository.sessionModelSubject
            .compactMap { $0 }
            .removeDuplicates()
            .dropFirst() // Skip initial session load - only react to actual session changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.checkForStatus()
                Task { @MainActor in
                    await self.checkForSessionChange()
                    await self.latencyRepo.checkLocationsValidity()
                }
            }
            .store(in: &cancellables)
    }

    func updateServerConfigs() {
        let timeNow = Date()
        let timePassed = Calendar.current.dateComponents([.hour], from: lastCheckForServerConfig, to: timeNow)
        if let hoursPassed = timePassed.hour {
            if hoursPassed > 23 {
                lastCheckForServerConfig = timeNow
                Task {
                    try? await credentialsRepo.getUpdatedOpenVPNCrendentials()
                    try? await credentialsRepo.getUpdatedServerConfig()
                }
            }
        }
    }

    func checkForStatus() {
        guard let status = userSessionRepository.sessionModel?.status else { return }
        if status != 1 {
            wgCredentials.delete()
        }
        if status == 3 {
            logger.logI("SessionManager", "User is banned.")
            vpnManager.simpleDisableConnection()
        } else if status == 2 && !locationsManager.isCustomConfigSelected() {
            logger.logI("SessionManager", "User is out of data.")
            vpnManager.simpleDisableConnection()
        }
    }

    private func updateProtocolCredentials() async {
        try? await credentialsRepo.getUpdatedIKEv2Crendentials()
        try? await credentialsRepo.getUpdatedOpenVPNCrendentials()
        wgCredentials.delete()
    }

    @MainActor
    func checkForSessionChange() async {
        logger.logD("SessionManager", "Comparing new session with old session.")
        guard let newSession = userSessionRepository.sessionModel,
              let oldSession = userSessionRepository.oldSessionModel else {
            logger.logI("SessionManager", "No old session found")
            return
        }
        if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
            logger.logI("SessionManager", "ALC changes detected. Request to retrieve server list")
            try? await locationListRepository.updateAll()
        }
        let sipCount = staticIPRepo.staticIPs.count
        if sipCount != newSession.getSipCount() {
            logger.logI("SessionManager", "SIP changes detected. Request to retrieve static ip list")
            _ = try? await staticIPRepo.updateStaticServers()
            await latencyRepo.loadStaticIpLatency()
        }
        if !newSession.isPremium && oldSession.isPremium {
            logger.logI("SessionManager", "User's pro plan expired.")
            _ = try? await Task.sleep(nanoseconds: 3_000_000_000)
            try? await locationListRepository.updateAll()
            await updateProtocolCredentials()
        }
        if newSession.isPremium && !oldSession.isPremium {
            try? await locationListRepository.updateAll()
            await updateProtocolCredentials()
        }
        if (oldSession.status == 3 && newSession.status == 1) || (oldSession.status == 2 && newSession.status == 1) {
            await updateProtocolCredentials()
        }

        let portMaps = portmapRepo.currentPortMaps.filter({ $0.heading == VPNProtocolType.wireGuard.identifier })
        if portMaps.first == nil {
            try? await locationListRepository.updatedServerList()
            _ = try? await portmapRepo.getUpdatedPortMap()
        }
        preferences.saveUserStatus(value: userSessionRepository.sessionModel?.isUserPro ?? false)
    }

    func logoutUser() {
        // Disconnect VPN
        vpnManager.simpleDisableConnection()

        if let window = windowProvider.mainWindow {
            window.rootViewController?.dismiss(animated: false, completion: nil)
#if os(iOS)
            let welcomeRootView = DeviceTypeProvider { Assembler.resolve(WelcomeView.self) }

            DispatchQueue.main.async {
                UIView.transition(
                    with: window,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                        window.rootViewController = UIHostingController(rootView: welcomeRootView)
                    },
                    completion: nil)
            }
#elseif os(tvOS)
            let firstViewController =  Assembler.resolve(WelcomeViewController.self)
            DispatchQueue.main.async {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = UINavigationController(rootViewController: firstViewController)
                }, completion: nil)
            }
#endif
        }

        // Reset VPN Profiles
        Task { @MainActor in
            await vpnManager.resetProfiles()
        }

        // Clear Apple SSO Session
        ssoManager.signOut()

        // Clear SSO Provider preference
        preferences.saveSSOProvider(provider: nil)

        // Delete Session
        Task {
            do {
                let response = try await self.apiManager.deleteSession()
                await MainActor.run {
                    if response.success {
                        logger.logI("SessionManager", "Session successfully deleted: \(response.message)")
                    } else {
                        logger.logI("SessionManager", "Delete session API returned failure: \(response.message)")
                    }
                }
            } catch let error {
                await MainActor.run {
                    logger.logE("SessionManager", "Failed to delete session after retries: \(error.localizedDescription)")
                }
            }
        }

        NotificationCenter.default.post(Notification(name: Notifications.userLoggedOut))

        // Clear the session
        userSessionRepository.clearSession()

        // Delete WireGuard Credentials
        wgCredentials.delete()

        // Clear Connection and notification count
        preferences.saveConnectionCount(count: 0)
        Assembler.resolve(PushNotificationManager.self).setNotificationCount(count: 0)

        // Clear the user information
        userSessionRepository.clean()

        // Clearn favourites, Saved session location
        preferences.clearFavourites()
        preferences.clearSessionAuth()
        preferences.clearSelectedLocations()
        preferences.saveLastUpdateCheckTimestamp(timeStamp: nil)
        preferences.saveLastUpdatePromptTimestamp(timeStamp: nil)

        Assembler.container.resetObjectScope(.userScope)
    }}
