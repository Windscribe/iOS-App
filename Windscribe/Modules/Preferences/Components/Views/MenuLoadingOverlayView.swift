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
    @Binding var isDarkMode: Bool
    var isFullScreen: Bool

    var body: some View {
        ZStack {
            if isFullScreen {
                Color.from(.actionBackgroundColor, isDarkMode)
                    .ignoresSafeArea()
            } else {
                Color.from(.actionBackgroundColor, isDarkMode).opacity(0.25)
                    .edgesIgnoringSafeArea(.all)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .from(.iconColor, isDarkMode)))
                .scaleEffect(1.5)
        }
    }
}
