//
//  SessionManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Swinject
import UIKit
import SwiftUI

class SessionManager: SessionManaging {
    var session: Session?
    var sessionNotificationToken: NotificationToken?
    var sessionTimer: Timer?
    var sessionFetchInProgress = false
    var lastCheckForServerConfig = Date()
    let wgCredentials = Assembler.resolve(WgCredentials.self)
    let logger = Assembler.resolve(FileLogger.self)
    let apiManager = Assembler.resolve(APIManager.self)
    var disposeBag = DisposeBag()
    let localDatabase = Assembler.resolve(LocalDatabase.self)
    let credentialsRepo = Assembler.resolve(CredentialsRepository.self)
    let serverRepo = Assembler.resolve(ServerRepository.self)
    let staticIPRepo = Assembler.resolve(StaticIpRepository.self)
    let portmapRepo = Assembler.resolve(PortMapRepository.self)
    let preferences = Assembler.resolve(Preferences.self)
    let latencyRepo = Assembler.resolve(LatencyRepository.self)
    let userRepo = Assembler.resolve(UserRepository.self)
    let locationsManager = Assembler.resolve(LocationsManager.self)

    private lazy var vpnManager: VPNManager = Assembler.resolve(VPNManager.self)
    private lazy var ssoManager = Assembler.resolve(SSOManaging.self)

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
        if !sessionFetchInProgress && preferences.getSessionAuthHash() != nil {
            sessionFetchInProgress = true

            // Use RxSwift properly for database operations, then convert to async for API
            localDatabase.getSession().first()
                .subscribe(onSuccess: { [weak self] savedSession in
                    guard let self = self else { return }

                    if savedSession != nil {
                        self.localDatabase.saveOldSession()

                        Task {
                            do {
                                let session = try await self.apiManager.getSession(nil)
                                await MainActor.run {
                                    self.userRepo.update(session: session)
                                    self.logger.logI("SessionManager", "Session updated for \(session.username)")
                                    self.sessionFetchInProgress = false
                                }
                            } catch {
                                await MainActor.run {
                                    self.logger.logE("SessionManager", "Failed to update error: \(error)")
                                    self.sessionFetchInProgress = false
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.logoutUser()
                            self.sessionFetchInProgress = false
                        }
                    }
                }, onFailure: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.logger.logE("SessionManager", "Failed to get saved session: \(error)")
                        self?.sessionFetchInProgress = false
                    }
                })
                .disposed(by: disposeBag)
        }
        updateServerConfigs()
    }

    func getUppdatedSession() -> Single<Session> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let session = try await self.apiManager.getSession(nil)
                    await MainActor.run {
                        self.userRepo.update(session: session)
                        single(.success(session))
                    }
                } catch {
                    await MainActor.run {
                        single(.failure(error))
                    }
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func canAccesstoProLocation() -> Bool {
        guard let session = session else { return false }
        return session.isPremium
    }

    func listenForSessionChanges() {
        localDatabase.getSession().subscribe(
            onNext: { session in
                self.session = session
                NotificationCenter.default.post(Notification(name: Notifications.sessionUpdated))
                self.checkForStatus()
                self.checkForSessionChange()
            }, onError: { error in
                self.logger.logE("SessionManager", "Realm user preferences notification error \(error.localizedDescription)")
            }
        ).disposed(by: disposeBag)
    }

    func updateServerConfigs() {
        let timeNow = Date()
        let timePassed = Calendar.current.dateComponents([.hour], from: lastCheckForServerConfig, to: timeNow)
        if let hoursPassed = timePassed.hour {
            if hoursPassed > 23 {
                lastCheckForServerConfig = timeNow
                credentialsRepo.getUpdatedOpenVPNCrendentials().flatMap { _ in
                    self.credentialsRepo.getUpdatedServerConfig()
                }.subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            }
        }
    }

    func checkForStatus() {
        guard let session = session else { return }
        if session.status != 1 {
            wgCredentials.delete()
        }
        if session.status == 3 {
            logger.logI("SessionManager", "User is banned.")
            vpnManager.simpleDisableConnection()
        } else if session.status == 2 && !locationsManager.isCustomConfigSelected() {
            logger.logI("SessionManager", "User is out of data.")
            vpnManager.simpleDisableConnection()
        }
    }

    private func loadLatency() {
        latencyRepo.loadAllServerLatency()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onCompleted: {
                self.logger.logI("SessionManager", "Successfully update latency.")
                self.refreshLocations()
            }, onError: { _ in
                self.logger.logI("SessionManager", "Failed to update latency.")
                self.refreshLocations()
            })
            .disposed(by: disposeBag)
    }

    private func refreshLocations() {
        Task { @MainActor in
            latencyRepo.pickBestLocation(pingData: localDatabase.getAllPingData())
            locationsManager.checkLocationValidity(checkProAccess: {canAccesstoProLocation()})
        }
    }

    private func checkLocationValidity() {
        Task { @MainActor in
            if vpnManager.isConnected() {
                latencyRepo.refreshBestLocation()
                locationsManager.checkLocationValidity(checkProAccess: {canAccesstoProLocation()})
            } else {
                loadLatency()
            }
        }
    }

    func checkForSessionChange() {
        logger.logD("SessionManager", "Comparing new session with old session.")
        guard let newSession = session, let oldSession = localDatabase.getOldSession() else {
            logger.logI("SessionManager", "No old session found")
            return
        }
        if oldSession.locHash != newSession.locHash {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
            logger.logI("SessionManager", "ALC changes detected. Request to retrieve server list")
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in
                self.checkLocationValidity()
            }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        let sipCount = localDatabase.getStaticIPs()?.count ?? 0
        if sipCount != newSession.getSipCount() {
            logger.logI("SessionManager", "SIP changes detected. Request to retrieve static ip list")
            staticIPRepo.getStaticServers().flatMap { _ in
                self.checkLocationValidity()
                return self.latencyRepo.loadStaticIpLatency()
            }.subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if !newSession.isPremium && oldSession.isPremium {
            logger.logI("SessionManager", "User's pro plan expired.")
            serverRepo.getUpdatedServers().delaySubscription(RxTimeInterval.seconds(3), scheduler: MainScheduler.asyncInstance).subscribe(
                onSuccess: { _ in
                    self.logger.logI("SessionManager", "Updated server list.")
                    self.checkLocationValidity()
                }, onFailure: { _ in
                    self.logger.logE("SessionManager", "Failed to update server list.")
                    self.checkLocationValidity()
                }
            ).disposed(by: disposeBag)
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if newSession.isPremium && !oldSession.isPremium {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if (oldSession.status == 3 && newSession.status == 1) || (oldSession.status == 2 && newSession.status == 1) {
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        guard let portMaps = localDatabase.getPortMap()?.filter({ $0.heading == wireGuard }) else { return }

        if portMaps.first == nil {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            portmapRepo.getUpdatedPortMap().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
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
        Task { [weak self] in
            guard let self = self else { return }

            var retryCount = 0
            let maxRetries = 3

            while retryCount < maxRetries {
                do {
                    let response = try await self.apiManager.deleteSession()
                    await MainActor.run {
                        if response.success {
                            self.logger.logI("SessionManager", "Session successfully deleted: \(response.message)")
                        } else {
                            self.logger.logI("SessionManager", "Delete session API returned failure: \(response.message)")
                        }
                    }
                    break
                } catch {
                    retryCount += 1
                    if retryCount >= maxRetries {
                        await MainActor.run {
                            self.logger.logE("SessionManager", "Failed to delete session after retries: \(error.localizedDescription)")
                        }
                        break
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay between retries
                }
            }
        }

        NotificationCenter.default.post(Notification(name: Notifications.userLoggedOut))

        // Clear the session
        session = nil

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
