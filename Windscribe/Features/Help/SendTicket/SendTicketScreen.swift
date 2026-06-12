//
//  SendTicketScreen.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct SendTicketScreen: View {
    @Environment(\.sessionProviding) private var sessionProviding
    @Environment(\.ticketManaging) private var ticketManaging
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        SendTicketContentView(viewModel: SendTicketScreenViewModel(
            sessionProviding: sessionProviding,
            ticketManaging: ticketManaging
        ))
        .navigationTitle(TextsAsset.SubmitTicket.submitTicket)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct SendTicketContentView: View {
    @State var viewModel: SendTicketScreenViewModel
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        if viewModel.showSuccess {
            // Success View
            BaseContentView {
                VStack(spacing: 24) {
                    Image(ImagesAsset.checkCircleGreen)
                        .resizable()
                        .frame(width: 86, height: 86)
                        .foregroundColor(Color.seaGreen)

                    Text(TextsAsset.SubmitTicket.weWillGetBackToYou)
                        .multilineTextAlignment(.center)
                        .font(.text(.callout))
                        .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            BaseContentView {
                // Form View
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        @Bindable var bindable = viewModel

                        // Description
                        Text(TextsAsset.SubmitTicket.fillInTheFields)
                            .font(.text(.footnote))
                            .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(Color.from(.backgroundColor, lookAndFeel.isDarkMode), lineWidth: 1)
                            )
                            .padding(.bottom, 14)

                        // Category Dropdown
                        HStack {
                            Text(TextsAsset.SubmitTicket.category)
                                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                                .font(.medium(.callout))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Menu {
                                ForEach(TextsAsset.SubmitTicket.categories, id: \.self) { option in
                                    Button(option) {
                                        viewModel.category = option
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.category)
                                        .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                                        .font(.regular(.callout))

                                    Image(ImagesAsset.dropDownIcon)
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                        .cornerRadius(12)
                        .padding(.bottom, 14)

                        // Email
                        Text("\(TextsAsset.SubmitTicket.email) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding(.bottom, 4)

                        TextField(TextsAsset.SubmitTicket.enterEmail, text: $bindable.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding()
                            .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                            .cornerRadius(9)
                            .padding(.bottom, 8)

                        Text(TextsAsset.SubmitTicket.soWeCanContactYou)
                            .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                            .font(.regular(.caption1))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 14)

                        // Subject
                        Text("\(TextsAsset.SubmitTicket.subject) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding(.bottom, 8)

                        TextField(TextsAsset.SubmitTicket.enterSubject, text: $bindable.subject)
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding()
                            .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                            .cornerRadius(9)
                            .padding(.bottom, 14)

                        // Message
                        Text("\(TextsAsset.SubmitTicket.whatsTheMatter) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding(.bottom, 8)

                        PlaceholderTextEditor(
                            isDarkMode: lookAndFeel.isDarkMode,
                            placeholderText: TextsAsset.SubmitTicket.tellUs,
                            textColor: viewModel.showError ? .red : .from(.titleColor, lookAndFeel.isDarkMode),
                            text: $bindable.message
                        )
                        .padding(16)
                        .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                        .cornerRadius(9)
                        .frame(height: 200)
                        .padding(.bottom, 14)

                        // Error Display
                        if viewModel.showError {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.text(.caption1))
                                .padding(.bottom, 8)
                        }

                        // Submit Button
                        Button(action: viewModel.sendTicket) {
                            if viewModel.showProgress {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 48)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(TextsAsset.send)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        viewModel.isFormValid ?
                                        Color.seaGreen :
                                            Color.from(.backgroundColor, lookAndFeel.isDarkMode)
                                    )
                                    .foregroundColor(
                                        viewModel.isFormValid ?
                                            .from(.titleColor, lookAndFeel.isDarkMode) :
                                                .from(.infoColor, lookAndFeel.isDarkMode)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(!viewModel.isFormValid)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}
