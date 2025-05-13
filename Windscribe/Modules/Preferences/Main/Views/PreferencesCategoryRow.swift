//
//  PreferencesCategoryRow.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesCategoryRow: View {
    let item: PreferenceItemType

    var body: some View {
        HStack(spacing: 12) {
            Image(item.imageName)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(tintColor)

            Text(item.title)
                .foregroundColor(.white)
                .font(.bold(.callout))
                .frame(maxWidth: .infinity, alignment: .leading)

            if item != .logout {
                Image(ImagesAsset.serverWhiteRightArrow)
                    .renderingMode(.template)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
    }

    private var tintColor: Color {
        if let uiColor = item.tint {
            return Color(uiColor)
        } else {
            return .primary
        }
    }
}

struct PreferencesActionButton: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let icon: Image?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    icon
                }
                Text(title)
                    .font(.text(.callout))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(25)
        }
    }
}
