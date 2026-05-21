//
//  AntiCensorshipOptionsView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct AntiCensorshipOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: AntiCensorshipOptionsViewModelImpl

    init(viewModel: any AntiCensorshipOptionsViewModel) {
        guard let model = viewModel as? AntiCensorshipOptionsViewModelImpl else {
            fatalError("AntiCensorshipOptionsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry,
                                      action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.Connection.antiCensorshipTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url, isDarkMode: viewModel.isDarkMode)
        }
    }
}
