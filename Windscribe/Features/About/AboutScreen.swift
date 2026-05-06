//
//  AboutScreen.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination. Reads `@Environment`, constructs the
/// view model, hands it to the inner `AboutView`. See "Routing" in
/// `docs/PROJECT_NEO.md` for the Screen/View/Route convention.
@available(iOS 17.0, *)
struct AboutScreen: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        AboutView(viewModel: AboutViewModel(lookAndFeel: lookAndFeel))
    }
}

@available(iOS 17.0, *)
private struct AboutView: View {

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
