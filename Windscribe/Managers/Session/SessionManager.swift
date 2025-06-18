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
    let locationsManager = Assembler.resolve(LocationsManagerType.self)

    private lazy var vpnManager: VPNManager = Assembler.resolve(VPNManager.self)

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
            localDatabase.getSession().first()
                .flatMap { savedSession in
                    if case _ = savedSession {
                        self.localDatabase.saveOldSession()
                        return self.apiManager.getSession(nil)
                    } else {
                        return Single.error(Errors.sessionIsInvalid)
                    }
                }.observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [weak self] session in
                    self?.userRepo.update(session: session)
                    self?.logger.logD("SessionManager", "Session updated for \(session.username)")
                    self?.sessionFetchInProgress = false
                }, onFailure: { [weak self] error in
                    if let errors = error as? Errors,
                       errors == .sessionIsInvalid {
                        self?.logoutUser()
                    } else {
                        self?.logger.logD("SessionManager", "Failed to update error")
                    }
                    self?.sessionFetchInProgress = false
                }).disposed(by: disposeBag)
        }
        updateServerConfigs()
    }

    func getUppdatedSession() -> Single<Session> {
        return apiManager.getSession(nil)
            .flatMap { session in
                self.userRepo.update(session: session)
                return Single.just(session)
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
                self.logger.logD("SessionManager", "Realm user preferences notification error \(error.localizedDescription)")
            }
        ).disposed(by: disposeBag)
    }

    func updateServerConfigs() {
        let timeNow = Date()
        let timePassed = Calendar.current.dateComponents([.hour], from: lastCheckForServerConfig, to: timeNow)
        if let hoursPassed = timePassed.hour {
            if hoursPassed > 23 {
                lastCheckForServerConfig = timeNow
                logger.logD("SessionManager", "Updating server configs.")
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
            logger.logD("SessionManager", "User is banned.")
            vpnManager.simpleDisableConnection()
        } else if session.status == 2 && !locationsManager.isCustomConfigSelected() {
            logger.logD("SessionManager", "User is out of data.")
            vpnManager.simpleDisableConnection()
        }
    }

    private func loadLatency() {
        latencyRepo.loadAllServerLatency()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onCompleted: {
                self.logger.logD("SessionManager", "Successfully update latency.")
                self.refreshLocations()
            }, onError: { _ in
                self.logger.logD("SessionManager", "Failed to update latency.")
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
            logger.logD("SessionManager", "No old session found")
            return
        }
        if oldSession.locHash != newSession.locHash {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
            logger.logD("SessionManager", "ALC changes detected. Request to retrieve server list")
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in
                self.checkLocationValidity()
            }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        let sipCount = localDatabase.getStaticIPs()?.count ?? 0
        if sipCount != newSession.getSipCount() {
            logger.logD("SessionManager", "SIP changes detected. Request to retrieve static ip list")
            staticIPRepo.getStaticServers().flatMap { _ in
                self.checkLocationValidity()
                return self.latencyRepo.loadStaticIpLatency()
            }.subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
        }
        if !newSession.isPremium && oldSession.isPremium {
            logger.logD("SessionManager", "User's pro plan expired.")
            serverRepo.getUpdatedServers().delaySubscription(RxTimeInterval.seconds(3), scheduler: MainScheduler.asyncInstance).subscribe(
                onSuccess: { _ in
                    self.logger.logD("SessionManager", "Updated server list.")
                    self.checkLocationValidity()
                }, onFailure: { _ in
                    self.logger.logD("SessionManager", "Failed to update server list.")
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

        NotificationCenter.default.post(Notification(name: Notifications.userLoggedOut))
        session = nil
        wgCredentials.delete()
        preferences.saveConnectionCount(count: 0)
        Assembler.resolve(PushNotificationManagerV2.self).setNotificationCount(count: 0)

        Task { @MainActor in
            await vpnManager.resetProfiles()
        }

        localDatabase.clean()
        preferences.clearFavourites()
        preferences.saveUserSessionAuth(sessionAuth: nil)
        preferences.clearSelectedLocations()
        Assembler.container.resetObjectScope(.userScope)
    }}
