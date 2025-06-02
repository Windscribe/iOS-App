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
        ScrollView {
            ZStack {
                VStack(alignment: .leading, spacing: 16) {
                    TextEditor(text: $viewModel.advanceParams)
                        .modifier(TextEditorInputModifiers())
                        .padding(12)
                        .foregroundColor(viewModel.showError ? .red : (viewModel.isDarkMode ? .white : .black))
                        .background(Color.nightBlue)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.showError ? Color.red : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .frame(height: 200)
                        .onChange(of: viewModel.advanceParams) { newValue in
                            viewModel.onAdvanceParamsTextChange(text: newValue)
                        }

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
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle(viewModel.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .dynamicTypeSize(dynamicTypeRange)
            .background(Color.nightBlue)
            .onAppear {
                viewModel.load()
            }
        }
        .overlay(loadingOverlay)
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
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .tint(.white)
        } else {
            content
        }
    }
}
