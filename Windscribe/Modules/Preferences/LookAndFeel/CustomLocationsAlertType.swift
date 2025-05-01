//
//  CustomLocationsAlertType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum CustomLocationsAlertType {
    case failedExport, failedImport, successfulImport, successfulReset

    var title: String {
        switch self {
        case .failedExport: TextsAsset.CustomLocationNames.exportTitleFailed
        case .failedImport: TextsAsset.CustomLocationNames.importTitleFailed
        case .successfulImport: TextsAsset.CustomLocationNames.importTitleSuccess
        case .successfulReset: TextsAsset.CustomLocationNames.resetTitleSuccess
        }
    }

    var message: String {
        switch self {
        case .failedExport: TextsAsset.CustomLocationNames.failedExporting
        case .failedImport: TextsAsset.CustomLocationNames.importTitleFailed
        case .successfulImport: TextsAsset.CustomLocationNames.importTitleSuccess
        case .successfulReset: TextsAsset.CustomLocationNames.resetTitleSuccess
        }
    }
}
