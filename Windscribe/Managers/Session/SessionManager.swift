//
//  SessionManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Swinject
import RxSwift

class SessionManager: SessionManagerV2 {
    var session: Session?
    var sessionNotificationToken: NotificationToken?
    var sessionTimer: Timer?
    var sessionFetchInProgress = false
    var lastCheckForServerConfig = Date()
    let wgCredentials = Assembler.resolve(WgCredentials.self)
    let logger =  Assembler.resolve(FileLogger.self)
    let vpnManager = Assembler.resolve(VPNManager.self)
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

    func setSessionTimer() {
        logger.logD(MainViewController.self, "60 seconds fetch session timer scheduled.")
        sessionTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.keepSessionUpdated), userInfo: nil, repeats: true)
        keepSessionUpdated()
        NotificationCenter.default.addObserver(self, selector: #selector(self.cancelTimers), name: Notifications.userLoggedOut, object: nil)
    }

    @objc func cancelTimers() {
        logger.logD(MainViewController.self, "Cancelled Session timer.")
        vpnManager.resetProperties()
        vpnManager.connectIntent = false
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    @objc func keepSessionUpdated() {
        if !sessionFetchInProgress && preferences.getSessionAuthHash() != nil {
            self.sessionFetchInProgress = true
            self.localDatabase.getSession().first()
                .flatMap { savedSession in
                    if  case let savedSession?? = savedSession {
                        self.logger.logD(self, "Cached session for \(savedSession.username)")
                        self.localDatabase.saveOldSession()
                        return self.apiManager.getSession(nil)
                    } else {
                        return Single.error(Errors.sessionIsInvalid)
                    }
                }.observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [self] session in
                    userRepo.update(session: session)
                    self.logger.logD(self, "Session updated for \(session.username)")
                    self.sessionFetchInProgress = false
                }, onFailure: { error in
                    self.vpnManager.handleConnectError()
                    if case Errors.sessionIsInvalid = error {
                        self.logoutUser()
                    } else {
                        self.logger.logE(self, "Failed to update error: \(error)")
                    }
                    self.sessionFetchInProgress = false
                }).disposed(by: disposeBag)
        }
        self.updateServerConfigs()
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
            },onError: { error in
                self.logger.logD(SessionManager.self, "Realm user preferences notification error \(error.localizedDescription)")
            }).disposed(by: disposeBag)
    }

    func updateServerConfigs() {
        let timeNow = Date()
        let timePassed = Calendar.current.dateComponents([.hour], from: lastCheckForServerConfig, to: timeNow)
        if let hoursPassed = timePassed.hour {
            if hoursPassed > 23 {
                lastCheckForServerConfig = timeNow
                self.logger.logD(SessionManager.self, "Updating server configs.")
                credentialsRepo.getUpdatedOpenVPNCrendentials().flatMap { _ in
                    return self.credentialsRepo.getUpdatedServerConfig()
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
            logger.logD(MainViewController.self, "User is banned.")
            vpnManager.disconnectAllVPNConnections(setDisconnect: true)
        } else if session.status == 2 && !vpnManager.isCustomConfigSelected() {
            logger.logD(MainViewController.self, "User is out of data.")
            vpnManager.disconnectAllVPNConnections(setDisconnect: true)
        }
    }

    private func loadLatency() {
        latencyRepo.loadAllServerLatency()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onCompleted: {
                self.logger.logD(self, "Successfully update latency.")
                self.vpnManager.checkLocationValidity()
            }, onError: { _ in
                self.logger.logD(self, "Failed to update latency.")
                self.latencyRepo.pickBestLocation(pingData: self.localDatabase.getAllPingData())
                self.vpnManager.checkLocationValidity()
            })
            .disposed(by: self.disposeBag)
    }

    func checkForSessionChange() {
        logger.logD(MainViewController.self, "Comparing new session with old session.")
        guard let newSession = session, let oldSession = localDatabase.getOldSession() else {
            logger.logD(self, "No old session found")
            return
        }
        if oldSession.locHash != newSession.locHash {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        if oldSession.getALCList() != newSession.getALCList() || (newSession.alc.count == 0 && oldSession.alc.count != 0) {
            logger.logD(MainViewController.self, "ALC changes detected. Request to retrieve server list")
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        let sipCount = localDatabase.getStaticIPs()?.count ?? 0
        if sipCount != newSession.getSipCount() {
            logger.logD(MainViewController.self, "SIP changes detected. Request to retrieve static ip list")
            staticIPRepo.getStaticServers().flatMap { _ in self.latencyRepo.loadStaticIpLatency()}.subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        if !newSession.isPremium && oldSession.isPremium {
            logger.logD(MainViewController.self, "User's pro plan expired.")
            serverRepo.getUpdatedServers().delaySubscription(RxTimeInterval.seconds(3), scheduler: MainScheduler.asyncInstance).subscribe(
                onSuccess: { _ in
                    self.logger.logD(self, "Updated server list.")
                    self.loadLatency()
                }, onFailure: { _ in
                    self.logger.logD(self, "Failed to update server list.")
                    self.loadLatency()
                }).disposed(by: disposeBag)
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        if newSession.isPremium && !oldSession.isPremium {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        if (oldSession.status == 3 && newSession.status == 1) || (oldSession.status == 2 && newSession.status == 1) {
            credentialsRepo.getUpdatedIKEv2Crendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
            credentialsRepo.getUpdatedOpenVPNCrendentials().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
        guard let portMaps = localDatabase.getPortMap()?.filter({$0.heading == wireGuard}) else { return }

        if portMaps.first == nil {
            serverRepo.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
            portmapRepo.getUpdatedPortMap().subscribe(onSuccess: { _ in }, onFailure: { _ in}).disposed(by: disposeBag)
        }
    }

    func logoutUser() {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
                window.rootViewController?.dismiss(animated: false, completion: nil)
                let firstViewController = Assembler.resolve(WelcomeViewController.self)
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = UINavigationController(rootViewController: firstViewController)
                }, completion: nil)
            }
            NotificationCenter.default.post(Notification(name: Notifications.userLoggedOut))
            self.session = nil
            self.wgCredentials.delete()
            self.preferences.saveConnectionCount(count: 0)
            Assembler.resolve(PushNotificationManagerV2.self).setNotificationCount(count: 0)
            self.vpnManager.resetProfiles {
                self.vpnManager.resetProperties()
                self.localDatabase.clean()
                self.preferences.clearFavourites()
                self.preferences.saveUserSessionAuth(sessionAuth: nil)
                self.vpnManager.selectedNode = nil
                Assembler.container.resetObjectScope(.userScope)
            }
        }
    }

    func reloadRootViewController() {
        #if os(iOS)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
            window.rootViewController?.dismiss(animated: false, completion: nil)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = UINavigationController(rootViewController: GeneralViewController())
            }, completion: nil)
        }
        #elseif os(tvOS)
        #endif
    }
}
