//
//  PreferencesBaseView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesBaseView<Content: View>: View {
    let isDarkMode: Bool
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
        }
        .background(Color.from(.screenBackgroundColor, isDarkMode).ignoresSafeArea())
    }
}
