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
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
}
