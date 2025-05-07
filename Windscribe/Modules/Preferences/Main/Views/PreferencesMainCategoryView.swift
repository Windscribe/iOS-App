//
//  PreferencesMainCategoryView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct PreferencesMainCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    @StateObject private var viewModel: PreferencesMainCategoryViewModelImpl
    @StateObject private var router: PreferencesNavigationRouter

    init(viewModel: any PreferencesMainCategoryViewModel, router: PreferencesNavigationRouter) {
        guard let model = viewModel as? PreferencesMainCategoryViewModelImpl else {
            fatalError("PreferencesMainCategoryView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 0) {
                    categoryRows()
                }
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                if viewModel.actionDisplay != .hideAll {
                    PreferencesActionButton(
                        title: actionButtonTitle(),
                        backgroundColor: .unconfirmedYellow,
                        textColor: .midnight,
                        icon: Image(ImagesAsset.warningBlack),
                        action: {
                            // TODO: Action
                        }
                    )
                }

                if viewModel.actionDisplay == .setupAccountAndLogin || viewModel.actionDisplay == .setupAccount {
                    PreferencesActionButton(
                        title: TextsAsset.login,
                        backgroundColor: .midnight,
                        textColor: .midnight,
                        icon: nil,
                        action: {
                            // TODO: Login
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.lightMidnight)
        .overlay(routeLink) // Keeps nav logic separate
        .edgesIgnoringSafeArea(.bottom)
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
    }

    @ViewBuilder
    private func categoryRows() -> some View {
        ForEach(viewModel.visibleItems) { item in
            if let index = viewModel.visibleItems.firstIndex(where: { $0.id == item.id }),
               !viewModel.shouldHideRow(index: index) {

                VStack(spacing: 0) {
                    Button {
                        if let route = item.routeID {
                            router.navigate(to: route)
                        } else if item == .logout {
                            viewModel.logout()
                        }
                    } label: {
                        PreferencesCategoryRow(item: item)
                            .frame(height: 48)
                            .contentShape(Rectangle())
                    }

                    if index < viewModel.visibleItems.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 2)
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var routeLink: some View {
        NavigationLink(
            destination: routeDestination,
            isActive: Binding(
                get: { router.activeRoute != nil },
                set: { newValue in
                    if !newValue {
                        router.pop()
                    }
                }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }

    @ViewBuilder
    private var routeDestination: some View {
        if let route = router.activeRoute {
            router.createView(for: route)
        } else {
            EmptyView()
        }
    }

    private func actionButtonTitle() -> String {
        switch viewModel.actionDisplay {
        case .email:
            return TextsAsset.addEmail
        case .emailGet10GB:
            return "\(TextsAsset.addEmail) (\(TextsAsset.get10GbAMonth))"
        case .setupAccount:
            return TextsAsset.setupAccount
        case .confirmEmail:
            return TextsAsset.EmailView.confirmEmail
        default:
            return ""
        }
    }
}
