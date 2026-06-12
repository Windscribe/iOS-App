//
//  MenuLoadingOverlayView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-27.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct MenuLoadingOverlayView: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    var isFullScreen: Bool
    var body: some View {
        ZStack {
            if isFullScreen {
                Color.from(.actionBackgroundColor, lookAndFeel.isDarkMode)
                    .ignoresSafeArea()
            } else {
                Color.from(.actionBackgroundColor, lookAndFeel.isDarkMode).opacity(0.25)
                    .edgesIgnoringSafeArea(.all)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .from(.iconColor, lookAndFeel.isDarkMode)))
                .scaleEffect(1.5)
        }
    }
}
