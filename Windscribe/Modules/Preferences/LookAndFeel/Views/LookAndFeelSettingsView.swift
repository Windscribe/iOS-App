//
//  LookAndFeelSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct LookAndFeelSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: LookAndFeelSettingsViewModelImpl

    init(viewModel: any LookAndFeelSettingsViewModel) {
        guard let model = viewModel as? LookAndFeelSettingsViewModelImpl else {
            fatalError("ReferForDataSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry,
                                      isDarkMode: viewModel.isDarkMode,
                                      action: { actionType in
                            viewModel.entrySelected(entry, actionSelected: actionType)
                        })
                    }
                    .padding(.top, 8)
                }
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .navigationTitle(TextsAsset.LookFeel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
