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

protocol LocationManagingViewModelType: DisclosureAlertDelegate {
    var shouldPresentLocationPopUp: PublishSubject<Bool> { get }
    func requestLocationPermission(callback: @escaping () -> Void)
    func logStatus()
    func getStatus() -> CLAuthorizationStatus
    func getAccuracyIsOff() -> Bool
}

class LocationManagingViewModel: NSObject, LocationManagingViewModelType {
    var connectivityManager: ProtocolManagerType
    var logger: FileLogger
    var shouldPresentLocationPopUp = PublishSubject<Bool>()
    private var connectivity: Connectivity
    private var wifiManager: WifiManager

    private var locationCallback: (() -> Void)?
    private let locationManager = CLLocationManager()

    init(connectivityManager: ProtocolManagerType, logger: FileLogger, connectivity: Connectivity, wifiManager: WifiManager) {
        self.connectivityManager = connectivityManager
        self.logger = logger
        self.connectivity = connectivity
        self.wifiManager = wifiManager
    }

    func requestLocationPermission(callback: @escaping () -> Void) {
        locationCallback = callback

        let status = getStatus()
        if getAccuracyIsOff() {
            if status == .notDetermined {
                showPermissionDisclousar()
            } else {
                showPermissionDisclousar(denied: true)
            }
            return
        }

        switch status {
        case .authorizedWhenInUse:
            callback()
        case .notDetermined:
            showPermissionDisclousar()
        case .denied:
            showPermissionDisclousar(denied: true)
        default:
            callback()
        }
    }

    func logStatus() {
        logger.logI(self, "\(getStatus())")
    }

    func getStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    func getAccuracyIsOff() -> Bool {
        return locationManager.accuracyAuthorization == .reducedAccuracy
    }
}

extension LocationManagingViewModel: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didFailWithError _: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        connectivity.refreshNetwork()
        if manager.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse {
            locationCallback?()
            // The SSID can only be otained after there are location permissions
            // We need to update the networks now
            connectivityManager.saveCurrentWifiNetworks()
        }
    }

    func showPermissionDisclousar(denied: Bool = false) {
        shouldPresentLocationPopUp.onNext(denied)
    }
}

extension LocationManagingViewModel: DisclosureAlertDelegate {
    func grantPermissionClicked() {
        logger.logD(self, "Location Permission granted")
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func openLocationSettingsClicked() {
        logger.logD(self, "Opening settings for location permission")
        UIApplication.shared.open(URL.init(string: "App-prefs:Privacy&path=LOCATION")!,
                                  options: [:], completionHandler: nil)
    }
}
