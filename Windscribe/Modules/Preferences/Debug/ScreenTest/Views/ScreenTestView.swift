//
//  ScreenTestView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ScreenTestView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ScreenTestViewModelImpl
    @StateObject private var router: ScreenTestNavigationRouter

    init(viewModel: any ScreenTestViewModel, router: ScreenTestNavigationRouter) {
        guard let model = viewModel as? ScreenTestViewModelImpl else {
            fatalError("ScreenTestView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
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
        .onWillDisappear {
            HapticFeedbackGenerator.shared.run(level: .medium)
        }
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
                if let route = item.routeID {
                    viewModel.presentedScreen = route
                }
            } label: {
                MenuCategoryRow(item: item, isDarkMode: viewModel.isDarkMode)
            }
        }
    }

}

struct ScreenTestRouteWrapper: Identifiable {
    let id = UUID()
    let route: ScreenTestRouteID
}
