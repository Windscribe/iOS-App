//
//  AuthTabPicker.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-01.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

// MARK: - Toolbar Item Helper

/// Creates a trailing toolbar item for the AuthTabPicker.
struct AuthTabPickerToolbarItem: ToolbarContent {
    @Binding var selectedTab: AuthTab
    @Binding var isDarkMode: Bool
    var isVisible: Bool = true

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if isVisible {
                AuthTabPicker(selectedTab: $selectedTab, isDarkMode: $isDarkMode)
            }
        }
    }
}

// MARK: - Tab Picker View

struct AuthTabPicker: View {

    @Binding var selectedTab: AuthTab
    @Binding var isDarkMode: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.medium(.callout))
                        .foregroundColor(selectedTab == tab ? .white : .authTabUnselectedText)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(
                            selectedTab == tab
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.authTabSelectedGradientBase.opacity(0.20),
                                            Color.authTabSelectedGradientBase.opacity(0.12)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            selectedTab == tab
                                ? Capsule()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                : nil
                        )
                        .shadow(color: selectedTab == tab ? .black.opacity(0.25) : .clear, radius: 1, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.from(.backgroundColor, isDarkMode))
        .clipShape(Capsule())
    }
}
