//
//  DeviceTypeProvider.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-20.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

// Enum to represent device types and orientations
enum DeviceType {
    case iPhonePortrait
    case iPhoneLandscape
    case iPadPortrait
    case iPadLandscape
    case unknown
}

/// Custom Environment Key for `deviceType`
private struct DeviceTypeKey: EnvironmentKey {
    static let defaultValue: DeviceType = .unknown
}

extension EnvironmentValues {
    var deviceType: DeviceType {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
}

/// Acts as a "super parent" that injects `deviceType` into the environment
struct DeviceTypeProvider<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let content: () -> Content

    private var deviceType: DeviceType {
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            return .iPhonePortrait
        } else if horizontalSizeClass == .compact && verticalSizeClass == .compact {
            return .iPhoneLandscape
        } else {
            return .unknown  // Default until geometry decides for iPad
        }
    }

    var body: some View {
        GeometryReader { geometry in
            content()
                .environment(\.deviceType, determineDeviceType(geometry: geometry))
        }
    }

    /// Determines device type, including iPad orientation
    private func determineDeviceType(geometry: GeometryProxy) -> DeviceType {
        if deviceType == .unknown { // iPad logic
            return geometry.size.width > geometry.size.height ? .iPadLandscape : .iPadPortrait
        } else {
            return deviceType
        }
    }
}
