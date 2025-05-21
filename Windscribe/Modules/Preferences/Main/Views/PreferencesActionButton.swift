//
//  PreferencesActionButton.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

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
                    .padding(12)
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
        }
    }
}
