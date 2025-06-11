//
//  NetworkSecurityView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct NetworkSecurityView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: NetworkOptionsSecurityViewModelImpl
    @StateObject private var router: ConnectionsNavigationRouter

    init(viewModel: any NetworkOptionsSecurityViewModel) {
        guard let model = viewModel as? NetworkOptionsSecurityViewModelImpl else {
            fatalError("NetworkSecurityView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: viewModel.router)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    if let entry = viewModel.autoSecureEntry {
                        MenuEntryView(item: entry,
                                      isDarkMode: viewModel.isDarkMode,
                                      action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                    if let entry = viewModel.currentNetworkEntry {
                        VStack(spacing: 0) {
                            Text(TextsAsset.NetworkSecurity.currentNetwork.uppercased())
                                .font(.caption)
                                .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MenuEntryView(item: entry,
                                          isDarkMode: viewModel.isDarkMode,
                                          action: { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            })
                        }
                    }
                    if let entry = viewModel.networkListEntry {
                        VStack(spacing: 0) {
                            Text(TextsAsset.NetworkSecurity.allNetwork.uppercased())
                                .font(.caption)
                                .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MenuEntryView(item: entry,
                                          isDarkMode: viewModel.isDarkMode,
                                          action: { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            })
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.NetworkSecurity.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(routeLink)
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { viewModel.router.activeRoute != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.router.pop()
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }
    @ViewBuilder
    private var routeDestination: some View {
        if let route = viewModel.router.activeRoute {
            viewModel.router.createView(for: route)
        } else {
            EmptyView()
        }
    }
}
