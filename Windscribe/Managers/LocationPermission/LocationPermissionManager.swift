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
import Combine
import UIKit

protocol LocationPermissionManaging {
    var locationStatusSubject: CurrentValueSubject<CLAuthorizationStatus, Never> { get }
    var shouldShowPermissionUI: PassthroughSubject<Void, Never> { get }

    func waitForPermission() async
    func requestLocationPermission()
    func logStatus()
    func getStatus() -> CLAuthorizationStatus
    func getAccuracyIsOff() -> Bool
    func grantPermission()
    func openSettings()
    func permissionPopupClosed()
}

final class LocationPermissionManager: NSObject, LocationPermissionManaging {
    private let locationManager = CLLocationManager()

    let locationStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)
    let shouldShowPermissionUI = PassthroughSubject<Void, Never>()

    private let connectivityManager: ProtocolManagerType
    private let logger: FileLogger
    private let connectivity: ConnectivityManager
    private let wifiManager: WifiManager

    private var hasBeenAuthorizedWhenInUse = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(connectivityManager: ProtocolManagerType,
         logger: FileLogger,
         connectivity: ConnectivityManager,
         wifiManager: WifiManager) {
        self.connectivityManager = connectivityManager
        self.logger = logger
        self.connectivity = connectivity
        self.wifiManager = wifiManager

        super.init()

        locationManager.delegate = self
    }

    func requestLocationPermission() {
        let status = getStatus()

        if getAccuracyIsOff() {
            shouldShowPermissionUI.send(())
            locationStatusSubject.send(status == .notDetermined ? .notDetermined : .denied)
            return
        }

        switch status {
        case .notDetermined, .denied:
            shouldShowPermissionUI.send(())
            locationStatusSubject.send(status)
        case .authorizedWhenInUse:
            locationStatusSubject.send(status)
        default:
            locationStatusSubject.send(status)
        }
    }

    func waitForPermission() async {
        if let isAuthorised = await hasBeenAuthorizedWhenInUse.values.first(where: { _ in true }) {
            if isAuthorised {
                return
            }
        }
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
        locationManager.requestWhenInUseAuthorization()
    }

    func openSettings() {
        logger.logD("LocationPermissionManager", "Opening settings for location permission")
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }

    func permissionPopupClosed() {
        let status = locationStatusSubject.value
        let permissionGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        hasBeenAuthorizedWhenInUse.send(permissionGranted)
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationStatusSubject.send(status)

        connectivity.refreshNetwork()
        if status == .authorizedWhenInUse {
            connectivityManager.saveCurrentWifiNetworks()
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {}
}
