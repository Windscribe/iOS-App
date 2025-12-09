//
//  NetworkSettingsView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct NetworkSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @EnvironmentObject var networkFlowContext: NetworkFlowContext
    @StateObject private var viewModel: NetworkSettingsViewModelImpl

    init(viewModel: any NetworkSettingsViewModel) {
        guard let model = viewModel as? NetworkSettingsViewModelImpl else {
            fatalError("NetworkSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry,
                                      isDarkMode: viewModel.isDarkMode,
                                      action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            viewModel.updateDisplayingNetworks(with: networkFlowContext.displayNetwork)
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.NetworkDetails.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

final class NetworkFlowContext: ObservableObject {
    @Published var displayNetwork: WifiNetworkModel
    init(displayNetwork: WifiNetworkModel) {
        self.displayNetwork = displayNetwork
    }
}
