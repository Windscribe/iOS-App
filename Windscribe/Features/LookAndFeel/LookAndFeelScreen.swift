//
//  LookAndFeelScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

// MARK: - Screen

/// Top-level navigation destination for Look & Feel preferences. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
/// See "Routing" in `docs/PROJECT_NEO.md` for the Screen/View/Route convention.
@available(iOS 17.0, *)
struct LookAndFeelScreen: View {
    @Environment(\.lookAndFeel) private var lookAndFeel
    @Environment(\.lookAndFeelStoring) private var lookAndFeelStoring
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.backgroundFileStoring) private var backgroundFileStoring
    @Environment(\.soundFileStoring) private var soundFileStoring
    @Environment(\.locationNamesManaging) private var locationNamesManaging
    @Environment(\.logger) private var logger

    var body: some View {
        LookAndFeelContentView(viewModel: LookAndFeelViewModel(
            lookAndFeel: lookAndFeel,
            lookAndFeelStoring: lookAndFeelStoring,
            hapticFeedback: hapticFeedback,
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting,
            backgroundFileStoring: backgroundFileStoring,
            soundFileStoring: soundFileStoring,
            locationNamesManaging: locationNamesManaging,
            logger: logger
        ))
            .navigationTitle(TextsAsset.LookFeel.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct LookAndFeelContentView: View {
    @State private var viewModel: LookAndFeelViewModel

    init(viewModel: LookAndFeelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        ZStack {
            PreferencesContentView(entries: viewModel.entries) { entry, action in
                viewModel.entrySelected(entry, action: action)
            }

            NavigationLink(
                destination: SelectAppIconScreen(),
                isActive: $bindable.isNavigating,
                label: { EmptyView() }
            )
            .hidden()
        }
        .alert(viewModel.alertType.title, isPresented: $bindable.showAlert) {
            Button(TextsAsset.ok, role: .cancel) { }
        } message: {
            Text(viewModel.alertType.message)
        }
        .task {
            await viewModel.startObservers()
        }
        .onAppear {
            viewModel.refreshIconSelection()
        }
    }
}
