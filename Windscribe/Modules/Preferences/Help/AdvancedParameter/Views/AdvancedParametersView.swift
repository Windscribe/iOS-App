//
//  AdvancedParameterView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct AdvancedParametersView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @ObservedObject private var keyboard = KeyboardResponder()
    @StateObject private var viewModel: AdvancedParametersViewModelImpl

    init(viewModel: any AdvancedParametersViewModel) {
        guard let model = viewModel as? AdvancedParametersViewModelImpl else {
            fatalError("AdvancedParametersView must be initialized properly with ViewModelImpl")
        }
        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: viewModel.isDarkMode) {
            ScrollView {
                ZStack {
                    VStack(alignment: .leading, spacing: 16) {
                        TextEditor(text: $viewModel.advanceParams)
                            .font(.text(.callout))
                            .transparentScrolling()
                            .modifier(TextEditorInputModifiers())
                            .padding(12)
                            .foregroundColor(viewModel.showError ? .red : (.from(.titleColor, viewModel.isDarkMode)))
                            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                            .cornerRadius(16)
                            .onChange(of: viewModel.advanceParams) { newValue in
                                viewModel.onAdvanceParamsTextChange(text: newValue)
                            }
                            .frame(height: 200)
                        Button(action: {
                            viewModel.saveButtonTap()
                        }, label: {
                            Text(TextsAsset.save)
                                .font(.text(.callout))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.seaGreen)
                                .foregroundColor(.midnight)
                                .cornerRadius(24)
                        })
                    }
                    .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(viewModel.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .dynamicTypeSize(dynamicTypeRange)
            .onAppear {
                viewModel.load()
            }
            .overlay(loadingOverlay)
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.showProgressBar {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
                .allowsHitTesting(true)
                .zIndex(1)
        }
    }
}

struct TextEditorInputModifiers: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .background(Color.clear)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .tint(.white)
        } else {
            content
        }
    }
}

public extension View {
    func transparentScrolling() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
        } else {
            return onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}
