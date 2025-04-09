//
//  CustomTextField.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct LoginTextField: View {

    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    var title: String
    var placeholder: String
    var isSecure: Bool = false
    var showError: Bool = false
    var errorMessage: String?
    var showWarningIcon: Bool = false
    var showFieldErrorText: Bool = true

    @Binding var text: String
    @State private var isPasswordVisible: Bool = false

    var titleTapAction: (() -> Void)?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title with right-aligned warning icon
            HStack {
                if let titleTapAction = titleTapAction {
                    Button(action: {
                        titleTapAction()
                    }, label: {
                        Text(title)
                            .font(.medium(.callout))
                            .foregroundColor(showError ? .loginRegisterFailedField : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    })
                    .buttonStyle(.plain)
                } else {
                    Text(title)
                        .font(.medium(.callout))
                        .foregroundColor(showError ? .loginRegisterFailedField : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if showWarningIcon {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.loginRegisterFailedField)
                        .imageScale(.small)
                }
            }

            // Input Field
            ZStack(alignment: .trailing) {
                HStack {
                    ZStack {
                        TextField("", text: $text)
                            .opacity(isPasswordVisible || !isSecure ? 1 : 0)
                            .disabled(isSecure && !isPasswordVisible)
                            .keyboardType(keyboardType)
                            .tint(.white)

                        SecureField("", text: $text)
                            .opacity(isPasswordVisible || !isSecure ? 0 : 1)
                            .disabled(!(!isPasswordVisible && isSecure))
                            .keyboardType(keyboardType)
                            .tint(.white)
                    }
                    .foregroundColor(showError ? .loginRegisterFailedField : .white)
                    .modifier(LoginTextFieldModifiers(placeholder: placeholder, text: text))

                    if isSecure {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPasswordVisible.toggle()
                            }
                        }, label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        })
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showError ? Color.loginRegisterFailedField : Color.clear, lineWidth: 1)
                )
            }

            // Error Message (optional, align left)
            if let error = errorMessage, showError, showFieldErrorText {
                Text(error)
                    .font(.regular(.footnote))
                    .foregroundColor(.loginRegisterFailedField)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
    }
}

// MARK: - Modifiers

private struct LoginTextFieldModifiers: ViewModifier {
    var placeholder: String
    var text: String

    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.return)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
            }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { placeholder() }
            self
        }
    }
}
