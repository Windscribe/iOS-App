//
//  MenuTextFieldDialogView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-27.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct MenuTextFieldDialogView: View {
    let title: String
    let description: String
    let placeholder: String
    let isSecure: Bool
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @State private var input: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if isSecure {
                SecureField(placeholder, text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(placeholder, text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack {
                Button(TextsAsset.cancel, action: onCancel)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(TextsAsset.confirm, action: {
                    onConfirm(input)
                })
                .foregroundStyle(Color.white)
            }
        }
        .padding()
        .background(Color.nightBlue)
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}
