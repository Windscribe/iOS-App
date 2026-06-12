//
//  ReferForDataScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct ReferForDataScreen: View {
    @Environment(\.sessionProviding) private var sessionProviding
    @Environment(\.referAndSharing) private var referAndSharing

    var body: some View {
        ReferForDataView(
            viewModel: ReferForDataViewModel(
                sessionProviding: sessionProviding,
                referAndSharing: referAndSharing
            )
        )
    }
}

@available(iOS 17.0, *)
private struct ReferForDataView: View {
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: ReferForDataViewModel

    init(viewModel: ReferForDataViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        BaseContentView {
            ScrollView {
                VStack(spacing: 32) {
                    Image(ImagesAsset.windscribeHeart)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 104, height: 86)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                        .padding(.top, 75)

                    VStack(spacing: 16) {
                        Text(TextsAsset.Refer.shareWindscribeWithFriend)
                            .font(.bold(.title2))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.from(.titleColor, lookAndFeel.isDarkMode))
                            .padding(.bottom, 16)

                        ReferForDataFeatureCheckRow(
                            text: TextsAsset.Refer.getAdditionalPerMonth
                        )

                        ReferForDataFeatureCheckRow(
                            text: TextsAsset.Refer.goProTo
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                    Button {
                        viewModel.shareInviteLinkSelected()
                    } label: {
                        Text(TextsAsset.Refer.shareInviteLink)
                            .font(.text(.callout))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.seaGreen)
                            .foregroundColor(.midnight)
                            .cornerRadius(24)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    Text(TextsAsset.Refer.refereeMustProvideUsername)
                        .font(.text(.footnote))
                        .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $bindable.showShareSheet) {
            ShareSheetView(items: [viewModel.inviteMessage, viewModel.appStoreLink])
        }
    }
}

@available(iOS 17.0, *)
private struct ReferForDataFeatureCheckRow: View {
    @Environment(\.dynamicTypeDefaultRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(ImagesAsset.CheckMarkButton.on)
                .resizable()
                .frame(width: 12, height: 12)

            Text(text)
                .font(.text(.subheadline))
                .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(dynamicTypeRange)
    }
}
