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
    func updateSession(_ appleID: String) async throws
    func login(auth: String) async throws
    func updateFrom(session: Session)
    func keepSessionUpdated()
}

class SessionManagerImpl: SessionManager {
    var sessionNotificationToken: NotificationToken?
    var sessionTimer: Timer?
    var sessionFetchInProgress = false
    var lastCheckForServerConfig = Date()

    // Not circular dependencies
    private let wgCredentials: WgCredentials
    private let logger: FileLogger
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let credentialsRepo: CredentialsRepository
    private let serverRepo: ServerRepository
    private let staticIPRepo: StaticIpRepository
    private let portmapRepo: PortMapRepository
    private let preferences: Preferences
    private let latencyRepo: LatencyRepository
    private let userSessionRepository: UserSessionRepository
    private let locationsManager: LocationsManager
    private let vpnStateRepository: VPNStateRepository

    private let vpnManager: VPNManager
    private let ssoManager: SSOManaging

    private var cancellables = Set<AnyCancellable>()

    init (wgCredentials: WgCredentials,
          logger: FileLogger,
          apiManager: APIManager,
          localDatabase: LocalDatabase,
          credentialsRepo: CredentialsRepository,
          serverRepo: ServerRepository,
          staticIPRepo: StaticIpRepository,
          portmapRepo: PortMapRepository,
          preferences: Preferences,
          latencyRepo: LatencyRepository,
          userSessionRepository: UserSessionRepository,
          locationsManager: LocationsManager,
          vpnStateRepository: VPNStateRepository,
          vpnManager: VPNManager,
          ssoManager: SSOManaging) {
        self.wgCredentials = wgCredentials
        self.logger = logger
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.credentialsRepo = credentialsRepo
        self.serverRepo = serverRepo
        self.staticIPRepo = staticIPRepo
        self.portmapRepo = portmapRepo
        self.preferences = preferences
        self.userSessionRepository = userSessionRepository
        self.latencyRepo = latencyRepo
        self.locationsManager = locationsManager
        self.vpnStateRepository = vpnStateRepository
        self.vpnManager = vpnManager
        self.ssoManager = ssoManager

        keepSessionUpdated()
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
        Task { @MainActor in
            guard preferences.getSessionAuthHash() != nil else { return }

            guard let currentSession = localDatabase.getSessionSync() else {
                self.logoutUser()
                return
            }

            if userSessionRepository.sessionModel == nil {
                await userSessionRepository.update(sessionModel: SessionModel(session: currentSession))
            }

            localDatabase.saveOldSession()

            do {
                try await self.updateSession()
            } catch let error {
                if let errors = error as? Errors {
                    if (errors == .sessionIsInvalid  || errors == .validationFailure) {
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
        try await updateSessionUsing(token: nil)
    }

    func updateSession(_ appleID: String) async throws {
        try await updateSessionUsing(token: appleID)
    }

    @MainActor
    private func updateSessionUsing(token: String?, retryCount: Int = 0) async throws {
        // Check if update is already in progress
        guard !sessionFetchInProgress else { return }

        sessionFetchInProgress = true
        let session = try await apiManager.getSession(token)
        logger.logI("SessionManager", "Session updated for \(session.username)")
        processUpdatedSession(session: session)
        sessionFetchInProgress = false
    }

    func login(auth: String) async throws {
        let session = try await self.apiManager.getSession(sessionAuth: auth)
        wgCredentials.delete()
        if session.sessionAuthHash.isEmpty {
            session.sessionAuthHash = auth
        }
        updateFrom(session: session)
    }

    func updateFrom(session: Session) {
        processUpdatedSession(session: session)
    }

    private func processUpdatedSession(session: Session) {
        localDatabase.saveOldSession()
        localDatabase.saveSession(session: session)
        let model = SessionModel(session: session)
        Task {
            await userSessionRepository.update(sessionModel: model)
        }
    }

    func listenForSessionChanges() {
        userSessionRepository.sessionModelSubject
            .compactMap { $0 }
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
                    _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
                    _ = try? await credentialsRepo.getUpdatedServerConfig().value
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

    private func checkLocationValidity() {
        Task { @MainActor in

        }
    }

    @MainActor
    func checkForSessionChange() async {
        logger.logD("SessionManager", "Comparing new session with old session.")
        guard let newSession = userSessionRepository.sessionModel,
              let oldLocalSession = localDatabase.getOldSession() else {
            logger.logI("SessionManager", "No old session found")
            return
        }
        let oldSession = SessionModel(session: oldLocalSession)
        if oldSession.locHash != newSession.locHash {
            try? await serverRepo.updatedServers()
        }
        if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
            logger.logI("SessionManager", "ALC changes detected. Request to retrieve server list")
            try? await serverRepo.updatedServers()
        }
        let sipCount = localDatabase.getStaticIPs()?.count ?? 0
        if sipCount != newSession.getSipCount() {
            logger.logI("SessionManager", "SIP changes detected. Request to retrieve static ip list")
            _ = try? await staticIPRepo.getStaticServers()
            _ = try? await self.latencyRepo.loadStaticIpLatency().value
        }
        if !newSession.isPremium && oldSession.isPremium {
            logger.logI("SessionManager", "User's pro plan expired.")
            _ = try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.logger.logI("SessionManager", "Updated server list.")
            try? await serverRepo.updatedServers()
            _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
            _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
        }
        if newSession.isPremium && !oldSession.isPremium {
            try? await serverRepo.updatedServers()
            _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
            _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
        }
        if (oldSession.status == 3 && newSession.status == 1) || (oldSession.status == 2 && newSession.status == 1) {
            _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
            _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
        }
        guard let portMaps = localDatabase.getPortMap()?.filter({ $0.heading == wireGuard }) else { return }

        if portMaps.first == nil {
            try? await serverRepo.updatedServers()
            _ = try? await portmapRepo.getUpdatedPortMap()
        }
    }

    func logoutUser() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
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

        // Disconnect VPN
        NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))

        // Reset VPN Profiles
        Task { @MainActor in
            await vpnManager.resetProfiles()
        }

        // Clear Apple SSO Session
        ssoManager.signOut()

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

        // Clear the local data base
        localDatabase.clean()

        // Clearn favourites, Saved session location
        preferences.clearFavourites()
        preferences.saveUserSessionAuth(sessionAuth: nil)
        preferences.clearSelectedLocations()

        Assembler.container.resetObjectScope(.userScope)
    }}
