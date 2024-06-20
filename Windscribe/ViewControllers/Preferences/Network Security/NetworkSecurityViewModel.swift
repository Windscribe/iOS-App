//
//  NetworkSecurityViewModel.swift
//  Windscribe
//
//  Created by Thomas on 16/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import RxSwift

protocol NetworkSecurityViewModelType {
    var networks: BehaviorSubject<[WifiNetwork]> {get}
    var isDarkMode: BehaviorSubject<Bool> {get}
    var isOnline: BehaviorSubject<Bool> { get }
    func getAutoSecureNetworkStatus() -> Bool
    func updateAutoSecureNetworkStatus()
}

class NetworkSecurityViewModel: NetworkSecurityViewModelType {
    var autoSecureNetworkStatus = BehaviorSubject<Bool>(value: DefaultValues.autoSecureNewNetworks)
    var isDarkMode: BehaviorSubject<Bool>

    private let localDatabase: LocalDatabase, preferences: Preferences, connectivity: Connectivity
    var themeManager: ThemeManager
    private let disposeBag = DisposeBag()
    let networks: BehaviorSubject<[WifiNetwork]> = BehaviorSubject(value: [])
    let isOnline: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    private var isObserving = false

    init(localDatabase: LocalDatabase, preferences: Preferences,themeManager: ThemeManager, connectivity: Connectivity) {
        self.localDatabase = localDatabase
        self.preferences = preferences
        self.themeManager = themeManager
        self.connectivity = connectivity
        isDarkMode = themeManager.darkTheme
        load()
        loadNetwork()
    }

    private func load() {
        preferences.getAutoSecureNewNetworks().subscribe { data in
            self.autoSecureNetworkStatus.onNext(data ?? DefaultValues.hapticFeedback)
        }.disposed(by: disposeBag)
        connectivity.network.subscribe(onNext: { network in
            self.isOnline.onNext(network.networkType != .none)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    private func loadNetwork() {
        isObserving = true
        localDatabase.getNetworks().subscribe(
            onNext: { savedNetworks in
                self.networks.onNext(savedNetworks)
            },onError: { _ in
                self.networks.onNext([])
            },onCompleted: {
                self.isObserving = false
            }).disposed(by: disposeBag)
    }

    func getAutoSecureNetworkStatus() -> Bool {
        return (try? autoSecureNetworkStatus.value()) ?? DefaultValues.autoSecureNewNetworks
    }

    func updateAutoSecureNetworkStatus() {
        try? preferences.saveAutoSecureNewNetworks(autoSecure: !autoSecureNetworkStatus.value())
    }
}
