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
        ZStack {
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                ScrollView {
                    VStack {
                        ForEach(viewModel.entries, id: \.self) { entry in
                            MenuEntryView(item: entry,
                                          action: { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            })
                        }
                        .padding(.top, 8)
                    }
                }
                .dynamicTypeSize(dynamicTypeRange)
            }
            .navigationTitle(TextsAsset.LookFeel.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(viewModel.alertType.title, isPresented: $viewModel.showAlert) {
                Button(TextsAsset.ok, role: .cancel) { }
            } message: {
                Text(viewModel.alertType.message)
            }
            .onAppear {
                viewModel.refreshIconSelection()
            }

            routeLink
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
