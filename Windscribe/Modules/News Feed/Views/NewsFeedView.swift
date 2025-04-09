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

    @State private var safariURL: URL?
    @State private var hasLoaded = false

    init(viewModel: NewsFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 11 / 255.0, green: 15 / 255.0, blue: 22 / 255.0)
                    .ignoresSafeArea()

                VStack {
                    if viewModel.loadState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if case .error(let errorMessage) = viewModel.loadState {
                        Text("\(TextsAsset.error): \(errorMessage)")
                            .foregroundColor(.red)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.newsFeedData) { item in
                                    NewsFeedListItem(
                                        item: item,
                                        didTapExpand: {
                                            viewModel.didTapToExpand(id: item.id)
                                        },
                                        didTapAction: { actionLink in
                                            viewModel.didTapAction(action: actionLink)
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(Color(red: 24 / 255.0, green: 27 / 255.0, blue: 33 / 255.0, opacity: 1.0))
                            .mask(
                                RoundedRectangle(cornerRadius: 12)
                                    .padding(.horizontal)
                                    .padding(.vertical, 3)
                            )
                        }
                    }
                }
                .padding(.top, 1) // keeping the foreground color of navigation
                .onAppear {
                    if !hasLoaded {
                        viewModel.loadNewsFeedData()
                        hasLoaded = true
                    }
                }
                .onChange(of: viewModel.viewToLaunch) { view in
                    switch view {
                    case let .safari(url):
                        safariURL = url
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
                .sheet(item: $safariURL) { url in
                    SafariView(url: url)
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(TextsAsset.NewsFeed.title)
                            .font(.medium(.body))
                            .foregroundColor(.white)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                            .foregroundColor(.gray.opacity(0.8))
                    })
                    .padding(.trailing, 16)
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NewsFeedListItem: View {
    let item: NewsFeedDataModel
    let didTapExpand: () -> Void
    let didTapAction: (ActionLinkModel) -> Void

    var body: some View {
        NewsFeedDetailView(
            item: item,
            didTapExpand: didTapExpand,
            didTapAction: didTapAction
        )
        .background(Color.newsFeedDetailBackgroundColor)

        if !item.isLast {
            Rectangle()
                .foregroundColor(.newsFeedSeperatorColor)
                .frame(height: 0.5)
        }
    }
}
