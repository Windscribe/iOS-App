//
//  ConfirmEmailView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ConfirmEmailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange

    @StateObject var viewModel: ConfirmEmailViewModelImpl
    @StateObject private var router: AuthenticationNavigationRouter
    @State private var showingResendSuccessAlert = false

    init(viewModel: any ConfirmEmailViewModel, router: AuthenticationNavigationRouter) {
        guard let model = viewModel as? ConfirmEmailViewModelImpl else {
            fatalError("Confirm Email View must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        NavigationView {
            contentView
                .onReceive(viewModel.$shouldDismiss) { action in
                    if action {
                        dismiss()
                    }
                }
                .onReceive(viewModel.$resendEmailSuccess) { success in
                    if success {
                        showingResendSuccessAlert = true
                        viewModel.resendEmailSuccess = false
                    }
                }
                .alert(isPresented: $showingResendSuccessAlert) {
                    Alert(
                        title: Text(TextsAsset.ConfirmationEmailSentAlert.title),
                        message: Text(TextsAsset.ConfirmationEmailSentAlert.message),
                        dismissButton: .default(Text(TextsAsset.okay))
                    )
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
    }

    @ViewBuilder
    private var contentView: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Image(ImagesAsset.confirmEmail)
                    .resizable()
                    .frame(width: 68, height: 68)

                Text(TextsAsset.EmailView.confirmEmail)
                    .font(.bold(.title2))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(viewModel.session?.isUserPro == true ? TextsAsset.EmailView.infoPro : TextsAsset.EmailView.info)
                    .font(.text(.callout))
                    .dynamicTypeSize(dynamicTypeRange)
                    .foregroundColor(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)

                Button(action: {
                    viewModel.resendEmail()
                }, label: {
                    Text(TextsAsset.EmailView.resendEmail)
                        .font(.text(.callout))
                        .dynamicTypeSize(dynamicTypeRange)
                        .foregroundColor(Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white, lineWidth: 2)
                        )
                })
                .disabled(viewModel.resendButtonDisabled)
                .opacity(viewModel.resendButtonDisabled ? 0.35 : 1.0)
                .padding(.horizontal, 24)

                NavigationLink(
                    destination: router.createView(for: .enterEmail),
                    isActive: $router.shouldNavigateToEnterEmail
                ) {
                    Button(action: {
                        router.shouldNavigateToEnterEmail = true
                    }, label: {
                        Text(TextsAsset.EmailView.changeEmail)
                            .font(.text(.callout))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    })
                    .opacity(1.0)
                    .padding(.horizontal, 24)
                }

                Button(action: {
                    viewModel.updateSession()
                    viewModel.shouldDismiss = true
                }, label: {
                    Text(TextsAsset.EmailView.close)
                        .font(.bold(.callout))
                        .foregroundColor(Color.white.opacity(0.5))
                })
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nightBlue.edgesIgnoringSafeArea(.all))
    }
}
