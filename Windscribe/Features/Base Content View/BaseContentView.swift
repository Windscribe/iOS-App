//
//  BaseContentView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 19/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct BaseContentView<Content: View>: View {
    @Environment(\.lookAndFeel) private var lookAndFeel
    @Environment(\.hapticFeedback) private var hapticFeedback

    let content: () -> Content

    var body: some View {
        ZStack {
            Color.from(.screenBackgroundColor, lookAndFeel.isDarkMode)
                .ignoresSafeArea()
            content()
        }
        .onAppear {
            if hapticFeedback.hapticFeedbackEnabled {
                hapticFeedback.run(level: .medium)
            }
        }
    }
}
