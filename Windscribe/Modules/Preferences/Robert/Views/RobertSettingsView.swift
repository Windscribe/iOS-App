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
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        viewModel.infoSelected()
                    } label: {
                        ZStack {
                            Text(viewModel.description)
                                .foregroundColor(.infoGrey)
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
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    ForEach(viewModel.entries, id: \.self) { entry in
                        FilterView(filter: entry, action: { filter in
                            viewModel.filterSelected(filter)
                        })
                    }
                    Button {
                        viewModel.customRulesSelected()
                    } label: {
                        MenuEntryView(item: viewModel.customRulesEntry, action: { _ in
                            viewModel.customRulesSelected()
                        })
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
    let filter: RobertFilter
    let action: @MainActor (RobertFilter) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(ImagesAsset.DarkMode.filterIcons[filter.id] ?? "")
                .resizable()
                .frame(width: 16, height: 16)
            Text(filter.title)
                .font(.medium(.callout))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(filter.enabled ? TextsAsset.Robert.blocking : TextsAsset.Robert.allowing)
                .font(.regular(.footnote))
                .foregroundColor(filter.enabled ? .eletricBlue : .infoGrey)
            Button(action: {
                action(filter)
            }, label: {
                Image(filter.enabled ? ImagesAsset.SwitchButton.on : ImagesAsset.SwitchButton.off)
                    .resizable()
                    .frame(width: 40, height: 22)
            })
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}
