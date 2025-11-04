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
    func checkForSessionChange()
    func checkSession() async throws
}

class SessionManagerImpl: SessionManager {
    var sessionNotificationToken: NotificationToken?
    var sessionTimer: Timer?
    var sessionFetchInProgress = false
    var lastCheckForServerConfig = Date()
    let wgCredentials = Assembler.resolve(WgCredentials.self)
    let logger = Assembler.resolve(FileLogger.self)
    let apiManager = Assembler.resolve(APIManager.self)
    let localDatabase = Assembler.resolve(LocalDatabase.self)
    let credentialsRepo = Assembler.resolve(CredentialsRepository.self)
    let serverRepo = Assembler.resolve(ServerRepository.self)
    let staticIPRepo = Assembler.resolve(StaticIpRepository.self)
    let portmapRepo = Assembler.resolve(PortMapRepository.self)
    let preferences = Assembler.resolve(Preferences.self)
    let latencyRepo = Assembler.resolve(LatencyRepository.self)
    let userSessionRepo = Assembler.resolve(UserSessionRepository.self)
    let locationsManager = Assembler.resolve(LocationsManager.self)
    let vpnStateRepository: VPNStateRepository = Assembler.resolve(VPNStateRepository.self)

    let sessionRepository = Assembler.resolve(SessionRepository.self)

    private lazy var vpnManager: VPNManager = Assembler.resolve(VPNManager.self)
    private lazy var ssoManager = Assembler.resolve(SSOManaging.self)

    private var cancellables = Set<AnyCancellable>()

    init () {
        sessionRepository.keepSessionUpdatedTrigger.sink { [weak self]_ in
            self?.keepSessionUpdated()
        }
        .store(in: &cancellables)
    }

    func setSessionTimer() {
        sessionTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.keepSessionUpdated), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cancelTimers), name: Notifications.userLoggedOut, object: nil)
    }

    @objc func cancelTimers() {
        logger.logD("SessionManager", "Cancelled Session timer.")
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    @objc func keepSessionUpdated() {
        Task { @MainActor in
            if !sessionFetchInProgress && preferences.getSessionAuthHash() != nil {
                guard let savedSession = localDatabase.getSessionSync() else {
                    self.logoutUser()
                    return
                }
                sessionFetchInProgress = true
                localDatabase.saveOldSession()

                do {
                    let session = try await self.apiManager.getSession(nil)
                    self.userSessionRepo.update(session: session)
                    self.logger.logI("SessionManager", "Session updated for \(session.username)")
                    self.sessionFetchInProgress = false
                } catch let error {
                    if let errors = error as? Errors,
                       errors == .sessionIsInvalid {
                        self.logoutUser()
                    } else {
                        self.logger.logE("SessionManager", "Failed to update error: \(error)")
                    }
                    self.sessionFetchInProgress = false
                }

                updateServerConfigs()
            }
        }
    }

    func checkSession() async throws {
        let session = try await apiManager.getSession(nil)
        userSessionRepo.update(session: session)
    }

    func listenForSessionChanges() {
        localDatabase.getSession()
            .toPublisher(initialValue: nil)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("SessionManager", "Realm user preferences notification error \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] session in
                guard let self = self else { return }
                sessionRepository.updateSession(session)
                NotificationCenter.default.post(Notification(name: Notifications.sessionUpdated))
                self.checkForStatus()
                self.checkForSessionChange()
            })
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
        guard let status = sessionRepository.sessionStatus else { return }
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

    private func loadLatency() {
        Task { @MainActor in
            do {
                try await latencyRepo.loadAllServerLatency().value
                self.logger.logI("SessionManager", "Successfully update latency.")
            } catch let error {
                self.logger.logE("SessionManager", "Failed to update latency wit error: \(error).")
            }
            self.refreshLocations()
        }
    }

    private func refreshLocations() {
        Task { @MainActor in
            latencyRepo.pickBestLocation(pingData: localDatabase.getAllPingData())
            locationsManager.checkLocationValidity(checkProAccess: {sessionRepository.canAccesstoProLocation()})
        }
    }

    private func checkLocationValidity() {
        Task { @MainActor in
            if vpnStateRepository.isConnected() {
                latencyRepo.refreshBestLocation()
                locationsManager.checkLocationValidity(checkProAccess: {sessionRepository.canAccesstoProLocation()})
            } else {
                loadLatency()
            }
        }
    }

    func checkForSessionChange() {
        logger.logD("SessionManager", "Comparing new session with old session.")
        guard let newSession = sessionRepository.session,
              let oldSession = localDatabase.getOldSession() else {
            logger.logI("SessionManager", "No old session found")
            return
        }
        Task { @MainActor in
            if oldSession.locHash != newSession.locHash {
                _ = try? await serverRepo.getUpdatedServers()
            }
            if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
                logger.logI("SessionManager", "ALC changes detected. Request to retrieve server list")
                do {
                    _ = try await serverRepo.getUpdatedServers()
                    checkLocationValidity()
                } catch { }
            }
            let sipCount = localDatabase.getStaticIPs()?.count ?? 0
            if sipCount != newSession.getSipCount() {
                logger.logI("SessionManager", "SIP changes detected. Request to retrieve static ip list")
                _ = try? await staticIPRepo.getStaticServers()
                self.checkLocationValidity()
                _ = try? await self.latencyRepo.loadStaticIpLatency().value
            }
            if !newSession.isPremium && oldSession.isPremium {
                logger.logI("SessionManager", "User's pro plan expired.")
                _ = try? await Task.sleep(nanoseconds: 3_000_000_000)
                self.logger.logI("SessionManager", "Updated server list.")
                do {
                    _ = try await serverRepo.getUpdatedServers()
                } catch let error {
                    self.logger.logE("SessionManager", "Failed to update server list with error: \(error).")
                }
                self.checkLocationValidity()
                _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
                _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
            }
            if newSession.isPremium && !oldSession.isPremium {
                _ = try? await serverRepo.getUpdatedServers()
                _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
                _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
            }
            if (oldSession.status == 3 && newSession.status == 1) || (oldSession.status == 2 && newSession.status == 1) {
                _ = try? await credentialsRepo.getUpdatedIKEv2Crendentials().value
                _ = try? await credentialsRepo.getUpdatedOpenVPNCrendentials().value
            }
            guard let portMaps = localDatabase.getPortMap()?.filter({ $0.heading == wireGuard }) else { return }

            if portMaps.first == nil {
                _ = try? await serverRepo.getUpdatedServers()
                _ = try? await portmapRepo.getUpdatedPortMap()
            }
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
        sessionRepository.updateSession(nil)

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
