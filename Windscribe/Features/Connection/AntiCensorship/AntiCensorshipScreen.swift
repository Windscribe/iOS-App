//
//  AntiCensorshipScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct AntiCensorshipScreen: View {
    @Environment(\.antiCensorshipManaging) private var antiCensorshipManaging
    @Environment(\.logger) private var logger
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        AntiCensorshipContentView(viewModel: AntiCensorshipScreenViewModel(
            antiCensorshipManaging: antiCensorshipManaging,
            logger: logger
        ))
        .navigationTitle(TextsAsset.Connection.antiCensorshipTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct AntiCensorshipContentView: View {
    @Bindable var viewModel: AntiCensorshipScreenViewModel

    var body: some View {
        PreferencesContentView(entries: viewModel.entries) { entry, action in
            viewModel.entrySelected(entry, action: action)
        }
        .sheet(isPresented: $viewModel.showingSafari) {
            if let url = viewModel.safariURL {
                SafariView(url: url)
            }
        }
        .task {
            await viewModel.startObservers()
        }
    }
}
