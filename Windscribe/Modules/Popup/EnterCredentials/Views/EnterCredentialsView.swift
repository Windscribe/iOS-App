//
//  EnterCredentialsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct EnterCredentialsView: View, ResponsivePopupLayoutProvider {

    private enum Field: Hashable {
        case title, username, password
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @ObservedObject private var keyboard = KeyboardResponder()
    @FocusState private var focusedField: Field?
    @State private var fieldPositions: [String: Anchor<CGRect>] = [:]

    @EnvironmentObject var context: EnterCredentialsContext
    @StateObject private var viewModel: EnterCredentialsViewModelImpl

    init(viewModel: any EnterCredentialsViewModel) {
        guard let model = viewModel as? EnterCredentialsViewModelImpl else {
            fatalError("EnterCredentialsView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
                let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
                let maxWidth = getMaxWidth(for: geometry)

                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: viewModel.cancel) {
                            Image(ImagesAsset.closeIcon)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .padding(8)
                                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                        }
                        .frame(width: 32, height: 32)
                        .padding(.top, 16)
                    }

                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: topSpacer - 48)

                            headerSection
                            formSection(maxWidth: maxWidth)
                            saveCredentialsSection(maxWidth: maxWidth)
                            submitButtonSection(maxWidth: maxWidth)

                            Spacer(minLength: bottomPadding)
                        }
                        .padding(.bottom, keyboard.currentHeight + 16)
                        .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                        .background(attachPreferenceReader())
                    }
                    .onChange(of: focusedField) { field in
                        guard let field = field else { return }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            scrollToField(field, proxy: proxy, geometry: geometry)
                        }
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.from(.screenBackgroundColor, viewModel.isDarkMode).ignoresSafeArea())
                .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                    if shouldDismiss {
                        dismiss()
                    }
                }
                .onAppear {
                    if let config = context.config {
                        viewModel.setConfig(config, isUpdating: context.isUpdating)
                    }
                }
            }
            .toolbar { enterCredentialsToolbar() }
        }
        .dynamicTypeSize(dynamicTypeRange)
    }

    private var canSubmit: Bool {
        !viewModel.username.isEmpty && !viewModel.password.isEmpty
    }

    // MARK: Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(ImagesAsset.enterCredentials)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 57, height: 85)
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

            // Title
            Text(viewModel.isUpdating ? TextsAsset.EditCredentialsAlert.title : TextsAsset.EnterCredentialsAlert.title)
                .font(.bold(.title1))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                .multilineTextAlignment(.center)
                .dynamicTypeSize(dynamicTypeRange)
                .padding(.horizontal, 36)

            // Description
            Text(TextsAsset.EnterCredentialsAlert.message)
                .font(.text(.body))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(dynamicTypeRange)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: maxWidth)
    }

    private func formSection(maxWidth: CGFloat) -> some View {
        VStack(spacing: 14) {
            // Config Title field (conditional)
            if viewModel.isUpdating {
                TextField(TextsAsset.configTitle, text: $viewModel.title)
                    .font(.bold(.body))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.55))
                    .accentColor(.from(.iconColor, viewModel.isDarkMode))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(height: 50)
                    .background(Color.clear)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .title)
                    .id(Field.title)
                    .readingFrame(id: "title-anchor")
                    .overlay(
                        Rectangle()
                            .fill(Color.from(.iconColor, viewModel.isDarkMode).opacity(0.05))
                            .frame(height: 2),
                        alignment: .bottom
                    )
            }

            // Username field
            TextField(TextsAsset.Authentication.username, text: $viewModel.username)
                .font(.bold(.body))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.55))
                .accentColor(.from(.iconColor, viewModel.isDarkMode))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(height: 50)
                .background(Color.clear)
                .submitLabel(.done)
                .focused($focusedField, equals: .username)
                .id(Field.username)
                .readingFrame(id: "username-anchor")
                .overlay(
                    Rectangle()
                        .fill(Color.from(.iconColor, viewModel.isDarkMode).opacity(0.05))
                        .frame(height: 2),
                    alignment: .bottom
                )

            // Password field
            SecureField(TextsAsset.Authentication.password, text: $viewModel.password)
                .font(.bold(.body))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.55))
                .accentColor(.from(.iconColor, viewModel.isDarkMode))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .frame(height: 50)
                .background(Color.clear)
                .submitLabel(.done)
                .focused($focusedField, equals: .password)
                .id(Field.password)
                .readingFrame(id: "password-anchor")
                .overlay(
                    Rectangle()
                        .fill(Color.from(.iconColor, viewModel.isDarkMode).opacity(0.05))
                        .frame(height: 2),
                    alignment: .bottom
                )
                .onSubmit {
                    focusedField = nil
                }
        }
        .frame(maxWidth: maxWidth)
        .padding(.leading, 8)
    }

    private func saveCredentialsSection(maxWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(TextsAsset.EnterCredentialsAlert.saveCredentials)
                    .font(.text(.body))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(viewModel.saveCredentials
                      ? ImagesAsset.CheckMarkButton.on
                      : ImagesAsset.CheckMarkButton.off)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .frame(height: 50)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.saveCredentials.toggle()
            }

            Rectangle()
                .fill(Color.from(.iconColor, viewModel.isDarkMode).opacity(0.05))
                .frame(height: 2)
        }
        .frame(maxWidth: maxWidth)
        .padding(.top, 16)
        .padding(.leading, 8)
    }

    private func submitButtonSection(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.submit) {
            Text(viewModel.isUpdating ? TextsAsset.save : TextsAsset.connect)
                .font(.text(.body))
                .foregroundColor(canSubmit ? .midnight : .from(.iconColor, viewModel.isDarkMode))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canSubmit ? Color.seaGreen : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(canSubmit ? Color.clear : Color.from(.iconColor, viewModel.isDarkMode), lineWidth: 2)
                )
                .dynamicTypeSize(dynamicTypeRange)
                .clipShape(Capsule())
        }
        .frame(maxWidth: maxWidth)
        .padding(.top, 32)
        .padding(.horizontal, 48)
        .opacity(canSubmit ? 1.0 : 0.4)
        .disabled(!canSubmit)
    }
}

private extension EnterCredentialsView {
    func attachPreferenceReader() -> some View {
        GeometryReader { _ in
            Color.clear
                .onPreferenceChange(ViewFrameKey.self) { prefs in
                    self.fieldPositions = prefs
                }
        }
    }
}

private extension EnterCredentialsView {
    @ToolbarContentBuilder
    func enterCredentialsToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Button(action: {
                moveFocus(up: true)
            }, label: {
                Image(systemName: "chevron.up")
            })
            .disabled(viewModel.isUpdating ? focusedField == .title : focusedField == .password)

            Button(action: {
                moveFocus(up: false)
            }, label: {
                Image(systemName: "chevron.down")
            })
            .disabled(focusedField == .password)

            Spacer()

            Button(TextsAsset.Authentication.done) {
                focusedField = nil
            }
        }
    }
}

private extension EnterCredentialsView {
    private func moveFocus(up: Bool) {
        guard let current = focusedField else { return }
        let allFields: [Field] = viewModel.isUpdating
            ? [.title, .username, .password]
            : [.username, .password]

        guard let currentIndex = allFields.firstIndex(of: current) else { return }

        let nextIndex = up
            ? max(currentIndex - 1, 0)
            : min(currentIndex + 1, allFields.count - 1)

        focusedField = allFields[nextIndex]
    }

    private func scrollToField(_ field: Field, proxy: ScrollViewProxy, geometry: GeometryProxy) {
        let anchorId = "\(field)-anchor"

        guard let anchor = fieldPositions[anchorId] else { return }

        let fieldRect = geometry[anchor]
        let fieldBottomY = fieldRect.maxY

        let screenHeight = UIScreen.main.bounds.height
        let keyboardHeight = keyboard.currentHeight
        let keyboardToolbarHeight: CGFloat = 44
        let buffer: CGFloat = 16

        let visibleBottomY = screenHeight - keyboardHeight - keyboardToolbarHeight - buffer

        if fieldBottomY > visibleBottomY {
            withAnimation {
                proxy.scrollTo(field, anchor: .top)
            }
        }
    }
}

final class EnterCredentialsContext: ObservableObject {
    @Published var config: CustomConfigModel?
    @Published var isUpdating = false
}
