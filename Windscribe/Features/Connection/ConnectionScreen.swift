//
//  ConnectionScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct ConnectionScreen: View {
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.portMapProviding) private var portMapProviding
    @Environment(\.dnsSettingsManaging) private var dnsSettingsManaging
    @Environment(\.logger) private var logger
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        ConnectionContentView(viewModel: ConnectionScreenViewModel(
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting,
            portMapProviding: portMapProviding,
            dnsSettingsManaging: dnsSettingsManaging,
            logger: logger
        ))
        .navigationTitle(TextsAsset.Connection.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct ConnectionContentView: View {
    @State var viewModel: ConnectionScreenViewModel

    var body: some View {
        @Bindable var bindable = viewModel
        ZStack {
            PreferencesContentView(entries: viewModel.entries) { entry, action in
                viewModel.entrySelected(entry, action: action)
            }

            NavigationLink(
                destination: destinationView(),
                isActive: $bindable.isNavigating,
                label: { EmptyView() }
            )
            .hidden()
        }
        .sheet(isPresented: $bindable.showingSafari) {
            if let url = viewModel.safariURL {
                SafariView(url: url)
            }
        }
        .task {
            await viewModel.startObservers()
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let route = viewModel.navigationRoute {
            switch route {
            case .networkOptions:
                NetworkOptionsScreen()
            case .antiCensorshipOptions:
                AntiCensorshipScreen()
            }
        } else {
            EmptyView()
        }
    }
}
