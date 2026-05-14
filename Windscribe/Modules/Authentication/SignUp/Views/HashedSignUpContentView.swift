//
//  HashedSignUpContentView.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-01.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct HashedSignUpContentView: View {
    private static let defaultFileName = "windscribe-auth.key"

    @ObservedObject var viewModel: SignUpViewModelImpl
    @State private var safariURL: URL?
    @State private var fileError: String?
    @State private var isShowingCopiedFeedback = false
    @State private var copyFeedbackResetTask: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            explanationSection
            hashDisplay
            actionButtons
            voucherToggle
            voucherSection
            backupCheckbox
            apiOrNetworkErrorLabel
            signUpButton
            Spacer()
        }
        .fileExporter(
            isPresented: $viewModel.showFileExporter,
            document: MultiFormatDocument(
                documentInfo: DocumentFormatInfo(
                    fileData: viewModel.preImageData,
                    type: .data,
                    tempFileName: Self.defaultFileName
                )
            ),
            contentType: .data,
            defaultFilename: Self.defaultFileName
        ) { result in
            if case .failure(let error) = result {
                fileError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.data, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else {
                    fileError = "Unable to access the selected file."
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let data = try Data(contentsOf: url)
                    viewModel.loadHashFromFile(data)
                } catch {
                    fileError = error.localizedDescription
                }
            case .failure(let error):
                fileError = error.localizedDescription
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { fileError != nil },
            set: { if !$0 { fileError = nil } }
        )) {
            Alert(title: Text("Error"), message: Text(fileError ?? ""))
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url, isDarkMode: viewModel.isDarkMode)
        }
        .onChange(of: viewModel.accountHash) { _ in
            hideCopiedFeedback()
        }
        .onDisappear {
            copyFeedbackResetTask?.cancel()
            copyFeedbackResetTask = nil
        }
    }
}

// MARK: - Subviews

private extension HashedSignUpContentView {

    @ViewBuilder
    var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(TextsAsset.hashedTabExplanation)
                .font(.regular(.callout))
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { safariURL = URL(string: Links.learnMoreHashedLogin) }) {
                Text(TextsAsset.learnMore)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.7))
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    var hashDisplay: some View {
        ZStack {
            Text(formattedAccountHash)
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                .opacity(isShowingCopiedFeedback ? 0 : 1)

            if isShowingCopiedFeedback {
                Text(TextsAsset.copied)
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                    .transition(.opacity)
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.from(.backgroundColor, viewModel.isDarkMode))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
        )
    }

    @ViewBuilder
    var actionButtons: some View {
        HStack(spacing: 16) {
            hashActionButton(imageName: ImagesAsset.arrowRefresh) {
                viewModel.regenerateHash()
            }
            hashActionButton(imageName: ImagesAsset.arrowUpload) {
                viewModel.showFileImporter = true
            }
            hashActionButton(imageName: ImagesAsset.arrowDownload) {
                viewModel.showFileExporter = true
            }
            hashActionButton(imageName: ImagesAsset.copyClipboard) {
                viewModel.copyHash()
                showCopiedFeedback()
            }
        }
        .frame(maxWidth: .infinity)
    }

    var formattedAccountHash: String {
        viewModel.accountHash.formattedHash(splitAt: 18)
    }

    func hashActionButton(imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(imageName)
                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                .frame(width: 80, height: 48)
                .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func showCopiedFeedback() {
        copyFeedbackResetTask?.cancel()

        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingCopiedFeedback = true
        }

        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingCopiedFeedback = false
            }
            copyFeedbackResetTask = nil
        }
        copyFeedbackResetTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
    }

    func hideCopiedFeedback() {
        copyFeedbackResetTask?.cancel()
        copyFeedbackResetTask = nil
        isShowingCopiedFeedback = false
    }

    @ViewBuilder
    var voucherToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.voucherViewTapped()
            }
        }) {
            HStack {
                Text(TextsAsset.gotVoucherCode)
                    .font(.medium(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                Spacer()

                OptionalPill(isDarkMode: $viewModel.isDarkMode)

                Image(ImagesAsset.chevronDown)
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.isVoucherVisible ? 180 : 0))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isVoucherVisible)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var voucherSection: some View {
        if viewModel.isVoucherVisible {
            LoginTextField(
                title: "",
                placeholder: TextsAsset.Authentication.enterVoucherCode,
                text: $viewModel.voucherCode,
                isDarkMode: $viewModel.isDarkMode
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isVoucherVisible)
        }
    }

    @ViewBuilder
    var backupCheckbox: some View {
        Button(action: {
            viewModel.hasBackedUpHash.toggle()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.hasBackedUpHash ? "checkmark.square.fill" : "square")
                    .foregroundColor(viewModel.hasBackedUpHash
                        ? .loginRegisterEnabledButtonColor
                        : .from(.iconColor, viewModel.isDarkMode).opacity(0.5))
                    .font(.title3)

                Text(TextsAsset.hashedBackupConfirmation)
                    .font(.regular(.callout))
                    .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var apiOrNetworkErrorLabel: some View {
        switch viewModel.failedState {
        case .api(let msg), .network(let msg):
            Text(msg)
                .font(.regular(.footnote))
                .foregroundColor(.loginRegisterFailedField)
                .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    var signUpButton: some View {
        AuthActionButton(
            title: TextsAsset.Welcome.signup,
            isEnabled: viewModel.isContinueButtonEnabled,
            isLoading: viewModel.showLoadingView
        ) {
            viewModel.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)
        }
    }
}

// MARK: - Hash Display Formatting

private extension String {
    /// Splits the hash string at the given position with a newline
    /// for a fixed two-line display layout.
    func formattedHash(splitAt position: Int) -> String {
        guard count > position else { return self }
        let index = self.index(startIndex, offsetBy: position)
        return String(self[..<index]) + "\n" + String(self[index...])
    }
}
