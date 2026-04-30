//
//  AboutView.swift
//  Windscribe
//
//  Project Neo — canonical reference module (M0, ND-005).
//  Mirrors the legacy `AboutSettingsView` UI verbatim, but on the Neo stack:
//  `@Observable` view model via `@State`, dependencies via `@Environment`.
//  Copy this when starting a new feature.
//
//  Note the two-view split: `AboutView` reads the environment-injected
//  service, `AboutContent` owns the @State view model. This is the canonical
//  SwiftUI pattern for "construct an `@Observable` from an env value once."
//

import SwiftUI

@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        AboutContent(viewModel: AboutViewModel(lookAndFeel: lookAndFeel))
    }
}

@available(iOS 17.0, *)
private struct AboutContent: View {

    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @State private var viewModel: AboutViewModel

    init(viewModel: AboutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        PreferencesBaseView(isDarkMode: $bindable.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { item in
                        Button {
                            viewModel.entrySelected(item)
                        } label: {
                            MenuCategoryRow(item: item, isDarkMode: viewModel.isDarkMode)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .sheet(item: $bindable.safariURL) { url in
            SafariView(url: url, isDarkMode: viewModel.isDarkMode)
        }
        .navigationTitle(TextsAsset.About.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.observeDarkMode()
        }
    }
}
