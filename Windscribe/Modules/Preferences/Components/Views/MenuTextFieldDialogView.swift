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
    let isLazyCode: Bool
    let visibleLineCount: Int
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
            } else if isLazyCode {
                TextField(placeholder, text: Binding(
                    get: {
                        return input
                    },
                    set: { newValue in
                        input = newValue.formattedLazyLoginCode()
                    }
                ))
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                multilineTextField
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

    @ViewBuilder
    private var multilineTextField: some View {
        if #available(iOS 16, *), visibleLineCount > 1 {
            TextField(placeholder, text: $input, axis: .vertical)
                .lineLimit(visibleLineCount, reservesSpace: true)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        } else {
            TextField(placeholder, text: $input)
                .lineLimit(visibleLineCount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
