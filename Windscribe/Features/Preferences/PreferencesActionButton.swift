//
//  PreferencesActionButton.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesActionButton: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let actionType: PreferencesAction
    let action: () -> Void

    init(actionType: PreferencesAction, action: @escaping () -> Void) {
        self.actionType = actionType
        self.action = action
    }

    var body: some View {
        let actionDisplay = actionType.getActionDisplay(isDarkMode: lookAndFeel.isDarkMode)

        Button(action: action) {
            HStack {
                if let icon = actionDisplay.icon.map({ Image($0) }) {
                    icon
                }
                Text(actionDisplay.title)
                    .font(.text(.callout))
                    .multilineTextAlignment(.center)
                    .padding(12)
            }
            .frame(maxWidth: .infinity)
            .background(actionDisplay.backgroundColor)
            .foregroundColor(actionDisplay.textColor)
            .cornerRadius(12)
        }
    }
}
