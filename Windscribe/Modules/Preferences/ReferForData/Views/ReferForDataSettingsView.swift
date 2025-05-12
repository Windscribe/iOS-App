//
//  ReferForDataSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ReferForDataSettingsView: View {

    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ReferForDataSettingsViewModelImpl
    @State private var showShareSheet = false

    init(viewModel: any ReferForDataSettingsViewModel) {
        guard let model = viewModel as? ReferForDataSettingsViewModelImpl else {
            fatalError("ReferForDataSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.lightMidnight.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Image(ImagesAsset.windscribeHeart)
                        .resizable()
                        .frame(width: 104, height: 86)
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, 75)

                    VStack(spacing: 16) {
                        Text(TextsAsset.Refer.shareWindscribeWithFriend)
                            .font(.bold(.title2))
                            .multilineTextAlignment(.center)
                            .foregroundColor(viewModel.isDarkMode ? .white : .midnight)
                            .padding(.bottom, 16)

                        ReferForDataCheckRow(
                            text: TextsAsset.Refer.getAdditionalPerMonth,
                            isDarkMode: $viewModel.isDarkMode)

                        ReferForDataCheckRow(
                            text: TextsAsset.Refer.goProTo,
                            isDarkMode: $viewModel.isDarkMode)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                    Button(action: {
                        viewModel.markShareDialogShown()
                        showShareSheet = true
                    }, label: {
                        Text(TextsAsset.Refer.shareInviteLink)
                            .font(.text(.callout))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.seaGreen)
                            .foregroundColor(.midnight)
                            .cornerRadius(24)
                    })
                    .frame(height: 48)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    Text(TextsAsset.Refer.refereeMustProvideUsername)
                        .font(.text(.footnote))
                        .foregroundColor(viewModel.isDarkMode ? .white.opacity(0.5) : .midnight.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: [viewModel.inviteMessage, viewModel.appStoreLink])
        }
    }
}

struct ReferForDataCheckRow: View {
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    let text: String
    @Binding var isDarkMode: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(ImagesAsset.CheckMarkButton.on)
                .resizable()
                .frame(width: 12, height: 12)

            Text(text)
                .font(.text(.subheadline))
                .foregroundColor(isDarkMode ? .white.opacity(0.5) : .midnight.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(dynamicTypeRange)
    }
}
