//
//  NetworkOptionsScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct NetworkOptionsScreen: View {
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.wifiNetworkProviding) private var wifiNetworkProviding
    @Environment(\.connectivityObserving) private var connectivityObserving
    @Environment(\.logger) private var logger

    var body: some View {
        NetworkOptionsContentView(viewModel: NetworkOptionsScreenViewModel(
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting,
            wifiNetworkProviding: wifiNetworkProviding,
            connectivityObserving: connectivityObserving,
            logger: logger
        ))
        .navigationTitle(TextsAsset.NetworkSecurity.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct NetworkOptionsContentView: View {
    @State var viewModel: NetworkOptionsScreenViewModel
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        @Bindable var bindable = viewModel
        BaseContentView {
            ZStack {
                ScrollView {
                    VStack(spacing: 14) {
                        if let entry = viewModel.autoSecureEntry {
                            MenuEntryView(item: entry) { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            }
                        }

                        if let entry = viewModel.currentNetworkEntry {
                            VStack(spacing: 0) {
                                Text(TextsAsset.NetworkSecurity.currentNetwork.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                MenuEntryView(item: entry) { actionType in
                                    viewModel.entrySelected(entry, action: actionType)
                                }
                            }
                        }

                        if let entry = viewModel.networkListEntry {
                            VStack(spacing: 0) {
                                Text(TextsAsset.NetworkSecurity.allNetwork.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                MenuEntryView(item: entry) { actionType in
                                    viewModel.entrySelected(entry, action: actionType)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                NavigationLink(
                    destination: destinationView(),
                    isActive: $bindable.isNavigating,
                    label: { EmptyView() }
                )
                .hidden()
            }
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
            case .networkSettings(let network):
                NetworkSettingsScreen(network: network)
            }
        } else {
            EmptyView()
        }
    }
}
