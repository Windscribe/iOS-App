//
//  NewsFeedView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct NewsFeedView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: NewsFeedViewModel

    @State private var safariItem: SafariItem?

    init(viewModel: NewsFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                VStack {
                    if viewModel.loadState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(
                                tint: .from(.iconColor, viewModel.isDarkMode)))
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if case .error(let errorMessage) = viewModel.loadState {
                        Text("\(TextsAsset.error): \(errorMessage)")
                            .foregroundColor(.red)
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(viewModel.newsFeedData) { item in
                                    NewsFeedListItem(
                                        item: item,
                                        didTapExpand: {
                                            viewModel.didTapToExpand(id: item.id)
                                        },
                                        didTapAction: { actionLink in
                                            viewModel.didTapAction(action: actionLink)
                                        },
                                        isDarkMode: $viewModel.isDarkMode
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.top, 1) // keeping the foreground color of navigation
                .task {
                    await viewModel.loadNewsFeedData()
                }
                .onChange(of: viewModel.viewToLaunch) { view in
                    switch view {
                    case let .safari(url):
                        safariItem = nil
                        viewModel.viewToLaunch = .unknown

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            safariItem = SafariItem(url: url)
                        }
                    case let .payment(promo, pcpid):
                        if let currentController = UIApplication.shared.topMostViewController() {
                            viewModel.navigateToPromotionView(with: promo, and: pcpid, from: currentController)
                        }

                        DispatchQueue.main.async {
                            viewModel.viewToLaunch = .unknown
                        }
                    default:
                        break
                    }
                }
                .sheet(item: $safariItem) { item in
                    SafariView(url: item.url, isDarkMode: viewModel.isDarkMode)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(TextsAsset.NewsFeed.title)
                .navigationBarItems(
                    trailing: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                    })
                    .padding(.trailing, {
                        if #available(iOS 26.0, *) {
                            return 0
                        } else {
                            return 16
                        }
                    }())
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NewsFeedListItem: View {
    let item: NewsFeedDataModel
    let didTapExpand: () -> Void
    let didTapAction: (NewsFeedActionType) -> Void

    @Binding var isDarkMode: Bool

    var body: some View {
        NewsFeedDetailView(
            item: item,
            didTapExpand: didTapExpand,
            didTapAction: didTapAction,
            isDarkMode: $isDarkMode
        )
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    item.expanded
                    ? isDarkMode ? Color.newsFeedDetailExpandedBackgroundColor : Color.newsFeedDetailExpandBackgroundColorLight
                    : isDarkMode ? Color.newsFeedDetailBackgroundColor : Color.newsFeedDetailBackgroundColorLight
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
