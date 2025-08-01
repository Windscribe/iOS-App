//
//  LocationMainViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import CoreLocation
import Foundation
import NetworkExtension
import RxSwift
import UIKit

protocol LocationPermissionManaging {
    var locationStatusSubject: BehaviorSubject<CLAuthorizationStatus> { get }
    var shouldShowPermissionUI: PublishSubject<Void> { get }

    func requestLocationPermission()
    func requestLocationPermissionFlow() -> Single<Void>
    func logStatus()
    func getStatus() -> CLAuthorizationStatus
    func getAccuracyIsOff() -> Bool
    func grantPermission()
    func openSettings()
}

final class LocationPermissionManager: NSObject, LocationPermissionManaging {
    private let locationManager = CLLocationManager()

    let locationStatusSubject = BehaviorSubject<CLAuthorizationStatus>(value: .notDetermined)
    let shouldShowPermissionUI = PublishSubject<Void>()

    private let connectivityManager: ProtocolManagerType
    private let logger: FileLogger
    private let connectivity: Connectivity
    private let wifiManager: WifiManager

    init(connectivityManager: ProtocolManagerType,
         logger: FileLogger,
         connectivity: Connectivity,
         wifiManager: WifiManager) {
        self.connectivityManager = connectivityManager
        self.logger = logger
        self.connectivity = connectivity
        self.wifiManager = wifiManager
    }

    func requestLocationPermission() {
        let status = getStatus()

        if getAccuracyIsOff() {
            shouldShowPermissionUI.onNext(())
            emitStatus(for: status == .notDetermined ? .notDetermined : .denied)
            return
        }

        switch status {
        case .notDetermined, .denied:
            shouldShowPermissionUI.onNext(())
            emitStatus(for: status)
        case .authorizedWhenInUse:
            locationStatusSubject.onNext(status)
        default:
            locationStatusSubject.onNext(status)
        }
    }

    func requestLocationPermissionFlow() -> Single<Void> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(RxBridgeError.missingInitialValue))
                return Disposables.create()
            }

            let disposable = self.locationStatusSubject
                .filter { $0 == .authorizedWhenInUse }
                .take(1)
                .subscribe(onNext: { _ in
                    single(.success(()))
                })

            self.requestLocationPermission()

            return Disposables.create {
                disposable.dispose()
            }
        }
    }

    func emitStatus(for status: CLAuthorizationStatus) {
        locationStatusSubject.onNext(status)
    }

    func logStatus() {
        logger.logI("LocationPermissionManager", "\(getStatus())")
    }

    func getStatus() -> CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    func getAccuracyIsOff() -> Bool {
        locationManager.accuracyAuthorization == .reducedAccuracy
    }

    func grantPermission() {
        logger.logD("LocationPermissionManager", "Location Permission granted")
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func openSettings() {
        logger.logD("LocationPermissionManager", "Opening settings for location permission")
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationStatusSubject.onNext(status)

        connectivity.refreshNetwork()
        if status == .authorizedWhenInUse {
            connectivityManager.saveCurrentWifiNetworks()
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {}
}
