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

    @State private var characters: [String] = Array(repeating: "", count: 8)
    @FocusState private var focusedIndex: Int?
    @State private var isResettingInvalidInput = false

    private var isCodeComplete: Bool {
        characters.allSatisfy { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(title)
                    .font(.medium(.body))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(message)
                    .font(.regular(.body))
                    .foregroundColor((isDarkMode ? Color.white : Color.black).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    characterField(at: index)
                }

                Text("—")
                    .foregroundColor(isDarkMode ? .white : .black)
                    .font(.system(size: 24, weight: .regular))
                    .frame(width: 16)

                ForEach(4..<8, id: \.self) { index in
                    characterField(at: index)
                }
            }

            VStack(spacing: 8) {
                Button(action: {
                    if isCodeComplete {
                        onConfirm()
                    }
                }, label: {
                    Text(TextsAsset.continue)
                        .foregroundColor(isCodeComplete ? (isDarkMode ? .black : .white) : (isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5)))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(isCodeComplete ? (isDarkMode ? .white : .black) : (isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05)))
                        )
                })
                .disabled(!isCodeComplete)

                Button(action: onCancel) {
                    Text(TextsAsset.cancel)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color.alertDarkBackground : Color.white.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .onAppear {
            parseCombinedCode()
            focusedIndex = 0
        }
    }

    @ViewBuilder
    private func characterField(at index: Int) -> some View {
        TextField("", text: $characters[index])
            .focused($focusedIndex, equals: index)
            .autocapitalization(.allCharacters)
            .disableAutocorrection(true)
            .keyboardType(.asciiCapable)
            .multilineTextAlignment(.center)
            .foregroundColor(isDarkMode ? .white : .black)
            .font(.regular(.title3))
            .frame(width: 36, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
            )
            .onChange(of: characters[index]) { newValue in
                // If we're resetting due to invalid input, ignore this onChange trigger
                if isResettingInvalidInput {
                    isResettingInvalidInput = false
                    return
                }

                let formatted = formatCharacter(newValue)

                // If invalid character (newValue has content but formatted is empty)
                if !newValue.isEmpty && formatted.isEmpty {
                    // Set flag and reset to empty, stay on same field
                    isResettingInvalidInput = true
                    characters[index] = ""
                    return
                }

                // Update with formatted value if different
                if formatted != newValue {
                    characters[index] = formatted
                    return
                }

                updateCombinedCode()

                // Valid character entered - advance to next field
                if !formatted.isEmpty && index < 7 {
                    focusedIndex = index + 1
                }
            }
    }

    private func formatCharacter(_ input: String) -> String {
        let clean = input
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(1)
        return String(clean)
    }

    private func formatPart(_ input: String, maxLength: Int) -> String {
        let clean = input
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(maxLength)
        return String(clean)
    }

    private func updateCombinedCode() {
        let firstGroup = characters[0..<4].joined()
        let secondGroup = characters[4..<8].joined()

        if secondGroup.isEmpty {
            code = firstGroup
        } else {
            code = "\(firstGroup)-\(secondGroup)"
        }
    }

    private func parseCombinedCode() {
        let parts = code.split(separator: "-")

        // Parse first group (0-3)
        if parts.count >= 1 {
            let firstGroup = String(parts[0])
            for (index, char) in firstGroup.prefix(4).enumerated() {
                characters[index] = String(char)
            }
        }

        // Parse second group (4-7)
        if parts.count >= 2 {
            let secondGroup = String(parts[1])
            for (index, char) in secondGroup.prefix(4).enumerated() {
                characters[4 + index] = String(char)
            }
        }
    }
}
