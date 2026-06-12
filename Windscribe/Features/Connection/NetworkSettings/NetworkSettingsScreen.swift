//
//  NetworkSettingsScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct NetworkSettingsScreen: View {
    let network: WifiNetworkModel

    @Environment(\.wifiNetworkProviding) private var wifiNetworkProviding
    @Environment(\.wifiNetworkManaging) private var wifiNetworkManaging
    @Environment(\.connectivityObserving) private var connectivityObserving
    @Environment(\.portMapProviding) private var portMapProviding
    @Environment(\.vpnStateProviding) private var vpnStateProviding
    @Environment(\.protocolManaging) private var protocolManaging
    @Environment(\.vpnOnDemandManaging) private var vpnOnDemandManaging
    @Environment(\.logger) private var logger

    var body: some View {
        NetworkSettingsContentView(viewModel: NetworkSettingsScreenViewModel(
            network: network,
            wifiNetworkProviding: wifiNetworkProviding,
            wifiNetworkManaging: wifiNetworkManaging,
            connectivityObserving: connectivityObserving,
            portMapProviding: portMapProviding,
            vpnStateProviding: vpnStateProviding,
            protocolManaging: protocolManaging,
            vpnOnDemandManaging: vpnOnDemandManaging,
            logger: logger
        ))
        .navigationTitle(TextsAsset.NetworkDetails.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct NetworkSettingsContentView: View {
    @State var viewModel: NetworkSettingsScreenViewModel

    var body: some View {
        PreferencesContentView(entries: viewModel.entries) { entry, action in
            viewModel.entrySelected(entry, action: action)
        }
        .task {
            await viewModel.startObservers()
        }
    }
}
