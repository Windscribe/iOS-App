//
//  GeneralScreen.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct GeneralScreen: View {
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.languageStoring) private var languageStoring
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.pushNotifications) private var pushNotifications

    var body: some View {
        let viewModel = GeneralViewModel(
            hapticFeedback: hapticFeedback,
            languageStoring: languageStoring,
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting,
            pushNotifications: pushNotifications
        )

        GeneralContentView(viewModel: viewModel)
            .navigationTitle(TextsAsset.General.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct GeneralContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @State private var viewModel: GeneralViewModel

    init(viewModel: GeneralViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        BaseContentView {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry, action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .task {
            await viewModel.startObservers()
        }
    }
}
