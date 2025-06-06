//
//  ConnectionSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ConnectionSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ConnectionSettingsViewModelImpl
    @StateObject private var router: ConnectionsNavigationRouter

    init(viewModel: any ConnectionSettingsViewModel) {
        guard let model = viewModel as? ConnectionSettingsViewModelImpl else {
            fatalError("ConnectionSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: viewModel.router)
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
                    .padding(.top, 8)
                }
                .padding(.top, 8)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.Connection.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(routeLink)
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
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
