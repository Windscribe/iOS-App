//
//  CustomTextField.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct LoginTextField: View {

    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange

    var title: String
    var secondaryTitle: String?
    var placeholder: String
    var isSecure: Bool = false
    var showPasswordToggle: Bool = true
    var showError: Bool = false
    var errorMessage: String?
    var showWarningIcon: Bool = false
    var showFieldErrorText: Bool = true

    @Binding var text: String
    @Binding var isDarkMode: Bool
    var passwordVisible: Binding<Bool>?
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    var titleTapAction: (() -> Void)?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var trailingView: AnyView?

    private var strokeColor: Color {
        if showError {
            return .loginRegisterFailedField
        } else if isFocused {
            return .from(.titleColor, isDarkMode)
        }
        return .loginRegisterStrokeColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title with right-aligned warning icon
            HStack {
                if !title.isEmpty {
                    titleRow
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
                            .textContentType(textContentType)
                            .tint(.from(.iconColor, isDarkMode))
                            .focused($isFocused)

                        SecureField("", text: $text)
                            .opacity(isPasswordVisible || !isSecure ? 0 : 1)
                            .disabled(!(!isPasswordVisible && isSecure))
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .tint(.from(.iconColor, isDarkMode))
                            .focused($isFocused)
                    }
                    .foregroundColor(showError ? .loginRegisterFailedField : .from(.titleColor, isDarkMode))
                    .modifier(LoginTextFieldModifiers(placeholder: placeholder, text: text, isDarkMode: isDarkMode, showError: showError))

                    if isSecure && showPasswordToggle {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPasswordVisible.toggle()
                            }
                        }, label: {
                            Image(isPasswordVisible ? ImagesAsset.eyeOff : ImagesAsset.eye)
                                .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.5))
                        })

                        Spacer()
                            .frame(width: 12)
                    }

                    if let trailingView = trailingView {
                        trailingView
                    }
                }
                .padding()
                .background(Color.from(.backgroundColor, isDarkMode))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: 1)
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
        .onChange(of: passwordVisible?.wrappedValue) { newValue in
            if let newValue = newValue {
                isPasswordVisible = newValue
            }
        }
        .onChange(of: isPasswordVisible) { newValue in
            passwordVisible?.wrappedValue = newValue
        }
    }
}

// MARK: - Title Row

private extension LoginTextField {

    @ViewBuilder
    var titleRow: some View {
        if let titleTapAction = titleTapAction, let secondary = secondaryTitle {
            // Title on left, tappable secondary on right
            HStack {
                Text(title)
                    .font(.medium(.callout))
                    .foregroundColor(showError
                                     ? .loginRegisterFailedField
                                     : .from(.titleColor, isDarkMode))

                Spacer()

                Button(action: titleTapAction) {
                    Text(secondary)
                        .font(.regular(.callout))
                        .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.5))
                        .underline()
                }
                .buttonStyle(.plain)
            }
        } else if let secondary = secondaryTitle {
            // Inline secondary text (no tap action)
            (Text(title)
                .font(.medium(.callout))
                .foregroundColor(showError
                                 ? .loginRegisterFailedField
                                 : .from(.titleColor, isDarkMode))
            + Text(" \(secondary)")
                .font(.regular(.callout))
                .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.5)))
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let titleTapAction = titleTapAction {
            // Whole title is tappable
            Button(action: titleTapAction) {
                Text(title)
                    .font(.medium(.callout))
                    .foregroundColor(showError
                                     ? .loginRegisterFailedField
                                     : .from(.titleColor, isDarkMode))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        } else {
            // Plain title
            Text(title)
                .font(.medium(.callout))
                .foregroundColor(showError
                                 ? .loginRegisterFailedField
                                 : .from(.titleColor, isDarkMode))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Modifiers

private struct LoginTextFieldModifiers: ViewModifier {
    var placeholder: String
    var text: String
    var isDarkMode: Bool
    var showError: Bool

    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.return)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(showError ? .loginRegisterFailedField : .from(.titleColor, isDarkMode).opacity(0.5))
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
