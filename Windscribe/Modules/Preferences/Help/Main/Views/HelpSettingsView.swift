//
//  HelpSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct HelpSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: HelpSettingsViewModelImpl
    @StateObject private var router: HelpNavigationRouter

    init(viewModel: any HelpSettingsViewModel, router: HelpNavigationRouter) {
        guard let model = viewModel as? HelpSettingsViewModelImpl else {
            fatalError("HelpSettingsView must be initialized properly with ViewModelImpl")
        }
        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        renderEntry(entry)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
        .overlay(routeLink)
        .navigationTitle(TextsAsset.Help.helpMe)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.buttonText)))
        }
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url, isDarkMode: viewModel.isDarkMode)
        }
        .onChange(of: viewModel.selectedRoute) { route in
            switch route {
            case .sendTicket:
                router.navigate(to: .sendTicket)
            case .advancedParams:
                router.navigate(to: .advancedParameters)
            case .viewLog:
                router.navigate(to: .debugLog)
            default:
                break
            }

            viewModel.selectedRoute = nil
        }
    }

    @ViewBuilder
    private func renderEntry(_ entry: HelpMenuEntryType) -> some View {
        switch entry {
        case let .link(icon, title, subtitle, _):
            HelpInfoCardView(isDarkMode: viewModel.isDarkMode,
                             icon: icon,
                             title: title,
                             subtitle: subtitle) {
                viewModel.entrySelected(entry)
            }
        case let .communitySupport(redditURLString, discordURLString):
            HelpExpandableListView(
                isDarkMode: viewModel.isDarkMode,
                icon: ImagesAsset.Help.community,
                title: TextsAsset.Help.communitySupport,
                subtitle: TextsAsset.Help.bestPlacesTohelp,
                subItems: [
                    (title: TextsAsset.Help.reddit, urlString: redditURLString),
                    (title: TextsAsset.Help.discord, urlString: discordURLString)
                ]
            ) { selectedURLString in
                if let url = URL(string: selectedURLString) {
                    viewModel.safariURL = url
                }
            }
        case let .navigation(icon, title, subtitle, route):
            HelpNavigationRowView(isDarkMode: viewModel.isDarkMode,
                                  icon: icon,
                                  title: title,
                                  subtitle: subtitle) {
                viewModel.entrySelected(.navigation(icon: icon, title: title, subtitle: subtitle, route: route))
            }
        case let .sendDebugLog(icon, title):
            HelpSendDebugLogView(isDarkMode: viewModel.isDarkMode,
                                 icon: icon,
                                 title: title,
                                 progressText: TextsAsset.Debug.sendingLog,
                                 sentText: TextsAsset.Debug.sentLog,
                                 status: viewModel.sendLogStatus) {
                viewModel.entrySelected(.sendDebugLog(icon: icon, title: title))
            }
        }
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { router.activeRoute != nil },
                set: { newValue in
                    if !newValue {
                        router.pop()
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
        if let route = router.activeRoute {
            router.createView(for: route)
        } else {
            EmptyView()
        }
    }
}
