//
//  LazyLoginCodeAlertView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2026-01-07.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct LazyLoginCodeAlertView: View {

    let title: String
    let message: String
    @Binding var code: String
    let isDarkMode: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var firstPart: String = ""
    @State private var secondPart: String = ""
    @FocusState private var focusedField: CodeField?

    enum CodeField: Hashable {
        case first
        case second
    }

    var body: some View {
        VStack(spacing: 15) {
            Text(title)
                .font(.semiBold(.headline))
                .foregroundColor(isDarkMode ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(message)
                .font(.callout)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                TextField("", text: $firstPart)
                .focused($focusedField, equals: .first)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .multilineTextAlignment(.center)
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                )
                .onChange(of: firstPart) { newValue in
                    let formatted = formatPart(newValue, maxLength: 4)
                    if formatted != newValue {
                        firstPart = formatted
                    }
                    updateCombinedCode()
                    if formatted.count == 4 {
                        focusedField = .second
                    }
                }

                Text("—")
                    .foregroundColor(isDarkMode ? .white : .black)

                TextField("", text: $secondPart)
                .focused($focusedField, equals: .second)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .multilineTextAlignment(.center)
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                )
                .onChange(of: secondPart) { newValue in
                    let formatted = formatPart(newValue, maxLength: 4)
                    if formatted != newValue {
                        secondPart = formatted
                    }
                    updateCombinedCode()
                }
            }

            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text(TextsAsset.cancel)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
                        )
                }

                Button(action: onConfirm) {
                    Text(TextsAsset.confirm)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isDarkMode ? Color.grayishDarkColor.opacity(0.95) : Color.white.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .onAppear {
            parseCombinedCode()
            focusedField = .first
        }
    }

    private func formatPart(_ input: String, maxLength: Int) -> String {
        let clean = input
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(maxLength)
        return String(clean)
    }

    private func updateCombinedCode() {
        if secondPart.isEmpty {
            code = firstPart
        } else {
            code = "\(firstPart)-\(secondPart)"
        }
    }

    private func parseCombinedCode() {
        let parts = code.split(separator: "-")
        if parts.count >= 1 {
            firstPart = String(parts[0])
        }
        if parts.count >= 2 {
            secondPart = String(parts[1])
        }
    }
}
