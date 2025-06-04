//
//  AboutSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct AboutSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: AboutSettingsViewModelImpl

    init(viewModel: any AboutSettingsViewModel) {
        guard let model = viewModel as? AboutSettingsViewModelImpl else {
            fatalError("AboutSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries) { item in
                        Button {
                            viewModel.entrySelected(item)
                        } label: {
                            MenuCategoryRow(isDarkMode: viewModel.isDarkMode, item: item)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
        .navigationTitle(TextsAsset.About.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
