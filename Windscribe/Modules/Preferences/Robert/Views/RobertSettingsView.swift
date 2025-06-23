//
//  RobertSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct RobertSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: RobertSettingsViewModelImpl

    init(viewModel: any RobertSettingsViewModel) {
        guard let model = viewModel as? RobertSettingsViewModelImpl else {
            fatalError("RobertSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        viewModel.infoSelected()
                    } label: {
                        ZStack {
                            Text(viewModel.description)
                                .foregroundColor(.from(.infoColor, viewModel.isDarkMode))
                                .multilineTextAlignment(.leading)
                                .font(.regular(.footnote))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            HStack {
                                Spacer()
                                Image(ImagesAsset.Robert.mask)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 189)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    .foregroundColor(.from(.backgroundColor, viewModel.isDarkMode))
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.from(.backgroundColor, viewModel.isDarkMode), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    ForEach(viewModel.entries, id: \.self) { entry in
                        FilterView(isDarkMode: viewModel.isDarkMode,
                                   filter: entry,
                                   action: { filter in
                            viewModel.filterSelected(filter)
                        })
                    }
                    Button {
                        viewModel.customRulesSelected()
                    } label: {
                        Text(viewModel.customRulesEntry.title)
                            .foregroundColor(.from(.titleColor, viewModel.isDarkMode))
                            .font(.medium(.callout))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(14)
                            .background(Color.from(.backgroundColor, viewModel.isDarkMode))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
        .navigationTitle(TextsAsset.Robert.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FilterView: View {
    let isDarkMode: Bool
    let filter: RobertFilter
    let action: @MainActor (RobertFilter) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(ImagesAsset.Robert.filterIcons[filter.id] ?? "")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.from(.iconColor, isDarkMode))
            Text(filter.title)
                .font(.medium(.callout))
                .foregroundColor(.from(.titleColor, isDarkMode))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(filter.enabled ? TextsAsset.Robert.blocking : TextsAsset.Robert.allowing)
                .font(.regular(.footnote))
                .foregroundColor(.from(.allowedColor(isEnabled: filter.enabled), isDarkMode))
            Button(action: {
                action(filter)
            }, label: {
                Image(filter.enabled ? ImagesAsset.SwitchButton.on : ImagesAsset.SwitchButton.off)
                    .resizable()
                    .frame(width: 40, height: 22)
            })
        }
        .padding(16)
        .background(Color.from(.backgroundColor, isDarkMode))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}
