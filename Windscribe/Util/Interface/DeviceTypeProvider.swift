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
    let content: () -> Content

    @State private var cachedDeviceType: DeviceType?
    @State private var previousSize: CGSize = .zero
    @State private var lastOrientation: UIDeviceOrientation = UIDevice.current.orientation

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .onAppear {
                        if cachedDeviceType == nil {
                            let newType = determineDeviceType(geometry: geometry)
                            cachedDeviceType = newType
                            previousSize = geometry.size
                            lastOrientation = UIDevice.current.orientation
                        }
                    }
                    .onChange(of: geometry.size) { newSize in
                        // Only respond to orientation-relevant changes
                        guard abs(newSize.width - previousSize.width) > 100 else { return }

                        let newType = determineDeviceType(geometry: geometry)
                        if newType != cachedDeviceType {
                            cachedDeviceType = newType
                            previousSize = newSize
                        }
                    }

                if let type = cachedDeviceType {
                    content()
                        .environment(\.deviceType, type)
                        .environment(\.dynamicTypeRange, dynamicRange(for: type))
                }
            }
        }
    }

    /// Determines device type, including iPad orientation
    private func determineDeviceType(geometry: GeometryProxy) -> DeviceType {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return isPad
            ? (geometry.size.width > geometry.size.height ? .iPadLandscape : .iPadPortrait)
            : (geometry.size.width > geometry.size.height ? .iPhoneLandscape : .iPhonePortrait)
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
