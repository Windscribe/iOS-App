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

private struct DynamicTypeRangeKey: EnvironmentKey {
    static let defaultValue: PartialRangeThrough<DynamicTypeSize> = ...DynamicTypeSize.medium
}

/// Injected environment value for dynamic type range, e.g., based on device type
extension EnvironmentValues {
    var deviceType: DeviceType {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }

    var dynamicTypeRange: PartialRangeThrough<DynamicTypeSize> {
        get { self[DynamicTypeRangeKey.self] }
        set { self[DynamicTypeRangeKey.self] = newValue }
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
            let type = determineDeviceType(geometry: geometry)

            content()
                .environment(\.deviceType, type)
                .environment(\.dynamicTypeRange, dynamicRange(for: type))
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

    /// Gather  appropriate dynamic type range based on device type
    private func dynamicRange(for type: DeviceType) -> PartialRangeThrough<DynamicTypeSize> {
        switch type {
        case .iPadPortrait, .iPadLandscape:
            return ...DynamicTypeSize.xLarge
        case .iPhonePortrait, .iPhoneLandscape:
            return ...DynamicTypeSize.large
        default:
            return ...DynamicTypeSize.medium
        }
    }
}
