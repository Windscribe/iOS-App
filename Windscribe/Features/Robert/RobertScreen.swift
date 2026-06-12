//
//  RobertScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for R.O.B.E.R.T. preferences. Reads
/// `@Environment`, constructs the view model, hands it to the inner view.
@available(iOS 17.0, *)
struct RobertScreen: View {
    @Environment(\.lookAndFeel) private var lookAndFeel
    @Environment(\.hapticFeedback) private var hapticFeedback
    @Environment(\.robertFiltering) private var robertFiltering
    @Environment(\.robertRuleURLProvider) private var robertRuleURLProvider
    @Environment(\.logger) private var logger

    var body: some View {
        let viewModel = RobertViewModel(
            hapticFeedback: hapticFeedback,
            filters: robertFiltering,
            ruleURLProvider: robertRuleURLProvider,
            logger: logger
        )

        RobertContentView(viewModel: viewModel)
            .navigationTitle(TextsAsset.Robert.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct RobertContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: RobertViewModel

    init(viewModel: RobertViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        ZStack {
            BaseContentView {
                ScrollView {
                    VStack(spacing: 16) {
                        infoCard

                        ForEach(viewModel.entries, id: \.self) { filter in
                            RobertFilterView(filter: filter) { selected in
                                viewModel.filterSelected(selected)
                            }
                        }

                        customRulesButton
                    }
                    .padding(.top, 8)
                }
                .dynamicTypeSize(dynamicTypeRange)
            }

            if viewModel.isLoading {
                MenuLoadingOverlayView(isFullScreen: false)
            }
        }
        .sheet(item: $bindable.safariURL) { url in
            SafariView(url: url)
        }
        .task {
            await viewModel.startObservers()
        }
    }

    private var infoCard: some View {
        ZStack {
            HStack {
                Spacer()
                Image(ImagesAsset.Robert.mask)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 189)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .foregroundColor(.from(.backgroundColor, lookAndFeel.isDarkMode))
            }
            DescriptionWithLearnMore(description: TextsAsset.Robert.description,
                                     action: viewModel.infoSelected)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.from(.backgroundColor, lookAndFeel.isDarkMode), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var customRulesButton: some View {
        Button {
            viewModel.customRulesSelected()
        } label: {
            Text(viewModel.customRulesEntry.title)
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                .font(.medium(.callout))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(14)
                .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
    }
}

@available(iOS 17.0, *)
private struct RobertFilterView: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let filter: RobertFilterModel
    let action: @MainActor (RobertFilterModel) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(ImagesAsset.Robert.filterIcons[filter.id] ?? "")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
            Text(filter.title)
                .font(.medium(.callout))
                .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(filter.enabled ? TextsAsset.Robert.blocking : TextsAsset.Robert.allowing)
                .font(.regular(.footnote))
                .foregroundColor(.from(.allowedColor(isEnabled: filter.enabled), lookAndFeel.isDarkMode))
            Button {
                action(filter)
            } label: {
                Image(filter.enabled ? ImagesAsset.SwitchButton.on : ImagesAsset.SwitchButton.off)
                    .resizable()
                    .frame(width: 40, height: 22)
            }
        }
        .padding(16)
        .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}
