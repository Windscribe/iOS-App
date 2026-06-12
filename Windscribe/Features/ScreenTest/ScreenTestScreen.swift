//
//  ScreenTestScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct ScreenTestScreen: View {

    var body: some View {
        ScreenTestContentView(
            viewModel: ScreenTestFeatureViewModel(),
            router: ScreenTestNavigationRouter()
        )
    }
}

@available(iOS 17.0, *)
private struct ScreenTestContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: ScreenTestFeatureViewModel
    @State private var router: ScreenTestNavigationRouter

    init(viewModel: ScreenTestFeatureViewModel, router: ScreenTestNavigationRouter) {
        _viewModel = State(initialValue: viewModel)
        _router = State(initialValue: router)
    }

    var body: some View {
        @Bindable var bindable = viewModel
        BaseContentView {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 14) {
                        categoryRows()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle("Screen Test")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: Binding(
            get: { viewModel.presentedScreen.map(ScreenTestRouteWrapper.init) },
            set: { _ in viewModel.presentedScreen = nil }
        )) { routeWrapper in
            router.createView(for: routeWrapper.route)
        }
    }

    @ViewBuilder
    private func categoryRows() -> some View {
        ForEach(viewModel.visibleItems, id: \.self) { item in
            Button {
                viewModel.itemSelected(item)
            } label: {
                MenuCategoryRow(item: item, isDarkMode: lookAndFeel.isDarkMode)
            }
        }
    }
}
