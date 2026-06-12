//
//  AdvancedParametersScreen.swift
//  Windscribe
//
//  Created by Claude on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct AdvancedParametersScreen: View {
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting

    var body: some View {
        AdvancedParametersContentView(viewModel: AdvancedParametersScreenViewModel(
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting
        ))
        .navigationTitle(TextsAsset.Preferences.advanceParameters)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct AdvancedParametersContentView: View {
    @State var viewModel: AdvancedParametersScreenViewModel
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        BaseContentView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        @Bindable var bindable = viewModel

                        TextEditor(text: $bindable.advanceParams)
                            .font(.text(.callout))
                            .transparentScrolling()
                            .modifier(TextEditorInputModifiers())
                            .padding(12)
                            .foregroundColor(
                                viewModel.showError ?
                                    .red :
                                        .from(.titleColor, lookAndFeel.isDarkMode)
                            )
                            .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                            .cornerRadius(16)
                            .onChange(of: viewModel.advanceParams) { _, newValue in
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
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Loading overlay
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
    }
}
