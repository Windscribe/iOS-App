//
//  HelpMeScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct HelpMeScreen: View {
    @Environment(\.sessionProviding) private var sessionProviding
    @Environment(\.debugLogManaging) private var debugLogManaging
    @Environment(\.connectivityObserving) private var connectivityObserving
    @Environment(\.logger) private var logger
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        HelpMeContentView(viewModel: HelpMeScreenViewModel(
            sessionProviding: sessionProviding,
            debugLogManaging: debugLogManaging,
            connectivityObserving: connectivityObserving,
            logger: logger
        ))
        .navigationTitle(TextsAsset.Help.helpMe)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct HelpMeContentView: View {
    @State var viewModel: HelpMeScreenViewModel
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        @Bindable var bindable = viewModel
        BaseContentView {
            ZStack {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(viewModel.entries, id: \.self) { entry in
                            renderEntry(entry)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                }

                NavigationLink(
                    destination: destinationView(),
                    isActive: $bindable.isNavigating,
                    label: { EmptyView() }
                )
                .hidden()
            }
        }
        .alert(item: $bindable.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.buttonText))
            )
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
    private func renderEntry(_ entry: HelpMenuEntryType) -> some View {
        switch entry {
        case let .link(icon, title, subtitle, _):
            HelpInfoCardView(
                isDarkMode: lookAndFeel.isDarkMode,
                icon: icon,
                title: title,
                subtitle: subtitle
            ) {
                viewModel.entrySelected(entry)
            }

        case let .communitySupport(redditURLString, discordURLString):
            HelpExpandableListView(
                isDarkMode: lookAndFeel.isDarkMode,
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
                    viewModel.showingSafari = true
                }
            }

        case let .navigation(icon, title, subtitle, _):
            HelpNavigationRowView(
                isDarkMode: lookAndFeel.isDarkMode,
                icon: icon,
                title: title,
                subtitle: subtitle
            ) {
                viewModel.entrySelected(entry)
            }

        case let .sendDebugLog(icon, title):
            HelpSendDebugLogView(
                isDarkMode: lookAndFeel.isDarkMode,
                icon: icon,
                title: title,
                progressText: TextsAsset.Debug.sendingLog,
                sentText: TextsAsset.Debug.sentLog,
                status: viewModel.sendLogStatus
            ) {
                viewModel.entrySelected(entry)
            }
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let route = viewModel.navigationRoute {
            switch route {
            case .sendTicket:
                SendTicketScreen()
            case .advancedParams:
                AdvancedParametersScreen()
            case .viewLog:
                ViewLogScreen()
            }
        } else {
            EmptyView()
        }
    }
}
