//
//  PreferencesBaseView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesBaseView<Content: View>: View {
    @Binding var isDarkMode: Bool
    var useHapticFeedback: Bool = true
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
        }
        .background(Color.from(.screenBackgroundColor, isDarkMode).ignoresSafeArea())
        .onAppear {
            if useHapticFeedback {
                HapticFeedbackGenerator.shared.run(level: .medium)
            }
        }
    }
}
