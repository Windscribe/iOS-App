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
                        .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Description
                        Text(TextsAsset.SubmitTicket.fillInTheFields)
                            .font(.text(.footnote))
                            .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(Color.from(.backgroundColor, viewModel.isDarkMode),
                                            lineWidth: 1)
                            )
                            .padding(.bottom, 14)

                        // Category Dropdown
                        HStack {
                            Text(TextsAsset.SubmitTicket.category)
                                .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
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
                                        .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                                        .font(.regular(.callout))

                                    Image(ImagesAsset.dropDownIcon)
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                        .cornerRadius(12)
                        .padding(.bottom, 14)

                        // Email
                        Text("\(TextsAsset.SubmitTicket.email) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .padding(.bottom, 4)

                        TextField(TextsAsset.SubmitTicket.enterEmail, text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .padding()
                            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                            .cornerRadius(9)
                            .padding(.bottom, 8)

                        Text(TextsAsset.SubmitTicket.soWeCanContactYou)
                            .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                            .font(.regular(.caption1))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 14)

                        // Subject
                        Text("\(TextsAsset.SubmitTicket.subject) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .padding(.bottom, 8)

                        TextField(TextsAsset.SubmitTicket.enterSubject, text: $viewModel.subject)
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .padding()
                            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                            .cornerRadius(9)
                            .padding(.bottom, 14)

                        // Message
                        Text("\(TextsAsset.SubmitTicket.whatsTheMatter) (\(TextsAsset.SubmitTicket.required))")
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .padding(.bottom, 8)

                        PlaceholderTextEditor(isDarkMode: viewModel.isDarkMode,
                                              placeholderText: TextsAsset.SubmitTicket.tellUs,
                                              textColor: viewModel.showError ? .red : (.from(.titleColor, viewModel.isDarkMode)),
                                              text: $viewModel.message)
                            .padding(16)
                            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
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
                                    .background(viewModel.isFormValid ? Color.seaGreen : Color.from(.backgroundColor, viewModel.isDarkMode))
                                    .foregroundColor(viewModel.isFormValid ?
                                        .from(.titleColor, viewModel.isDarkMode) :
                                            .from(.infoColor, viewModel.isDarkMode))
                                    .cornerRadius(12)
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

struct PlaceholderTextEditor: View {
    let isDarkMode: Bool
    let placeholderText: String
    let textColor: Color
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholderText)
                    .foregroundColor(.from(.infoColor, isDarkMode))
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }

            TextEditor(text: $text)
                .font(.text(.callout))
                .foregroundColor(textColor)
                .transparentScrolling()
                .modifier(TextEditorInputModifiers())
        }
    }
}
