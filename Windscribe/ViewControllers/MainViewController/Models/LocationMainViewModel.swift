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
}

class LocationManagingViewModel: NSObject, LocationManagingViewModelType {
    var connectivityManager: ConnectionManagerV2
    var logger: FileLogger
    var shouldPresentLocationPopUp = PublishSubject<Bool>()
    private var connectivity: Connectivity
    private var wifiManager: WifiManager

    private var locationCallback: (() -> Void)?
    private let locationManager = CLLocationManager()

    init(connectivityManager: ConnectionManagerV2, logger: FileLogger, connectivity: Connectivity, wifiManager: WifiManager) {
        self.connectivityManager = connectivityManager
        self.logger = logger
        self.connectivity = connectivity
        self.wifiManager = wifiManager
    }

    func requestLocationPermission(callback: @escaping () -> Void) {
        locationCallback = callback
        switch getStatus() {
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
        if #available(iOS 15.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
}

extension LocationManagingViewModel: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didFailWithError _: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        connectivity.refreshNetwork()
        if #available(iOS 15.0, *) {
            if manager.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse {
                locationCallback?()
                // The SSID can only be otained after there are location permissions
                // We need to update the networks now
                connectivityManager.saveCurrentWifiNetworks()
            }
        }
    }

    func showPermissionDisclousar(denied: Bool = false) {
        shouldPresentLocationPopUp.onNext(denied)
    }
}

extension LocationManagingViewModel: DisclosureAlertDelegate {
    func grantPermissionClicked() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func openLocationSettingsClicked() {
        UIApplication.shared.open(URL(string: "App-prefs:Privacy&path=LOCATION")!,
                                  options: [:], completionHandler: nil)
    }
}
