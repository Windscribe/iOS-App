//
//  SendTicketView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct SendTicketView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @ObservedObject private var keyboard = KeyboardResponder()
    @StateObject private var viewModel: SendTicketViewModelImpl

    init(viewModel: any SendTicketViewModel) {
        guard let model = viewModel as? SendTicketViewModelImpl else {
            fatalError("SendTicketView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        if viewModel.showSuccess {
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {

                VStack(spacing: 24) {
                    Image(ImagesAsset.checkCircleGreen)
                        .resizable()
                        .frame(width: 86, height: 86)
                        .foregroundColor(Color.seaGreen)

                    Text(TextsAsset.SubmitTicket.weWillGetBackToYou)
                        .multilineTextAlignment(.center)
                        .font(.text(.callout))
                        .foregroundColor(.infoGrey)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Description
                        Text(TextsAsset.SubmitTicket.fillInTheFields)
                            .font(.text(.footnote))
                            .foregroundColor(.infoGrey)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.bottom, 12)

                        // Category Dropdown
                        HStack {
                            Text(TextsAsset.SubmitTicket.category)
                                .fontWeight(.semibold)
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
                                        .foregroundColor(.infoGrey)
                                        .font(.regular(.callout))

                                    Image(ImagesAsset.dropDownIcon)
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.infoGrey)
                                }
                            }
                        }
                        .padding(.bottom, 12)

                        // Email
                        Text("\(TextsAsset.SubmitTicket.email) (\(TextsAsset.SubmitTicket.required)")
                            .font(.semiBold(.subheadline))
                            .padding(.bottom, 4)

                        TextField(TextsAsset.SubmitTicket.email, text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)

                        Text(TextsAsset.SubmitTicket.soWeCanContactYou)
                            .font(.text(.caption1))
                            .foregroundColor(.infoGrey)
                            .padding(.bottom, 12)

                        // Subject
                        Text("\(TextsAsset.SubmitTicket.subject) (\(TextsAsset.SubmitTicket.required)")
                            .font(.semiBold(.subheadline))
                            .padding(.bottom, 4)

                        TextField(TextsAsset.SubmitTicket.subject, text: $viewModel.subject)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.bottom, 12)

                        // Message
                        Text(TextsAsset.SubmitTicket.whatsTheIssue)
                            .font(.text(.headline))

                        VStack(alignment: .leading, spacing: 0) {
                            TextEditor(text: $viewModel.message)
                                .modifier(TextEditorInputModifiers())
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(viewModel.showError ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .frame(height: 200)
                        }
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Error Display
                        if viewModel.showError {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.text(.caption1))
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
                                    .background(viewModel.isFormValid ? Color.seaGreen : Color.gray.opacity(0.1))
                                    .foregroundColor(viewModel.isFormValid ? .midnight : .gray)
                                    .cornerRadius(24)
                            }
                        }
                        .disabled(!viewModel.isFormValid)

                    }
                    .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .dynamicTypeSize(dynamicTypeRange)
                    .navigationTitle(TextsAsset.SubmitTicket.submitTicket)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
