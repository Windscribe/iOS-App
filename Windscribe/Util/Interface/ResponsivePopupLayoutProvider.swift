//
//  PopupLayoutHelper.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

protocol ResponsivePopupLayoutProvider {
    var maxIphoneWidth: CGFloat { get }
    func getMaxWidth(for geometry: GeometryProxy) -> CGFloat
    func getBottomPadding(for geometry: GeometryProxy, deviceType: DeviceType) -> CGFloat
    func getTopSpacerHeight(for geometry: GeometryProxy, deviceType: DeviceType) -> CGFloat
}

extension ResponsivePopupLayoutProvider {
    var maxIphoneWidth: CGFloat { 430 }

    func getMaxWidth(for geometry: GeometryProxy) -> CGFloat {
        min(geometry.size.width, maxIphoneWidth)
    }

    func getBottomPadding(for geometry: GeometryProxy, deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPadPortrait:
            return geometry.size.height * 0.24
        case .iPadLandscape:
            return geometry.size.height * 0.12
        default:
            return 24
        }
    }

    func getTopSpacerHeight(for geometry: GeometryProxy, deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPadPortrait:
            return geometry.size.height * 0.24
        default:
            return geometry.size.height * 0.12
        }
    }
}
