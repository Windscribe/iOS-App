//
//  GeneralSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct GeneralSettingsView: View {
    @StateObject private var viewModel: GeneralSettingsViewModelImpl

    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    init(viewModel: any GeneralSettingsViewModel) {
        guard let model = viewModel as? GeneralSettingsViewModelImpl else {
            fatalError("GeneralSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry, isDarkMode: viewModel.isDarkMode, action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .navigationTitle(TextsAsset.General.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
