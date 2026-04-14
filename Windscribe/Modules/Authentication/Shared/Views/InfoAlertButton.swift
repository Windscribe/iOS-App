//
//  InfoAlertButton.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

struct InfoAlertButton: View {
    let title: String
    let message: String
    @Binding var isDarkMode: Bool

    private let alertManager: AlertManager = Assembler.resolve(AlertManager.self)

    var body: some View {
        Button(action: {
            alertManager.showSimpleAlert(
                title: title,
                message: message,
                buttonText: TextsAsset.okay
            )
        }, label: {
            Image(systemName: "info.circle")
                .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.5))
        })
        .buttonStyle(.plain)
    }
}
