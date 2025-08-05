//
//  ShakeForDataLeaderboardView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ShakeForDataLeaderboardView: View, ResponsivePopupLayoutProvider {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ShakeForDataLeaderboardModelImpl

    init(viewModel: any ShakeForDataLeaderboardModel) {
        guard let model = viewModel as? ShakeForDataLeaderboardModelImpl else {
            fatalError("ShakeForDataMainView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            VStack(spacing: 0) {
                // Leaderboard List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.leaderboardEntries) { entry in
                            leaderboardRow(entry: entry)
                            Rectangle()
                                .fill(Color.from(.infoColor, viewModel.isDarkMode))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)

                Spacer()
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationBarHidden(false)
        .navigationTitle(TextsAsset.Preferences.leaderboard)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func leaderboardRow(entry: ShakeForDataLeaderboardEntry) -> some View {
        HStack {
            Text(entry.user)
                .font(.bold(.callout))
                .foregroundColor(Color.from(entry.you ? .positive: .titleColor,
                                            viewModel.isDarkMode))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(entry.score)")
                .font(.bold(.callout))
                .foregroundColor(Color.from( entry.you ? .positive: .infoColor,
                                             viewModel.isDarkMode))
        }
    }
}
