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

    init(viewModel: any HelpSettingsViewModel) {
        guard let model = viewModel as? HelpSettingsViewModelImpl else {
            fatalError("HelpSettingsView must be initialized properly with ViewModelImpl")
        }
        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)

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
        .navigationTitle(TextsAsset.Help.helpMe)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(alert.buttonText)))
        }
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
    }

    @ViewBuilder
    private func renderEntry(_ entry: HelpMenuEntryType) -> some View {
        switch entry {
        case let .link(icon, title, subtitle, urlString):
            HelpInfoCardView(icon: icon, title: title, subtitle: subtitle) {
                viewModel.entrySelected(entry)
            }
        case let .communitySupport(redditURLString, discordURLString):
            HelpExpandableListView(
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
            HelpNavigationRowView(icon: icon, title: title, subtitle: subtitle) {
                viewModel.entrySelected(.navigation(icon: icon, title: title, subtitle: subtitle, route: route))
            }
        case let .sendDebugLog(icon, title):
            HelpSendDebugLogView(icon: icon,
                                 title: title,
                                 progressText: TextsAsset.Debug.sendingLog,
                                 sentText: TextsAsset.Debug.sentLog,
                                 status: viewModel.sendLogStatus) {
                viewModel.entrySelected(.sendDebugLog(icon: icon, title: title))
            }
        }
    }
}
