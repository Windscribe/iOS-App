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
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: PreferencesMainCategoryViewModelImpl
    @StateObject private var router: PreferencesNavigationRouter

    @State private var showConfirmEmailSheet: Bool = false

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
                VStack(spacing: 14) {
                    categoryRows()
                }
                .padding(.top, 8)
            }

            VStack(spacing: 12) {
                if viewModel.actionDisplay != .hideAll {
                    PreferencesActionButton(
                        title: actionButtonTitle(),
                        backgroundColor: .unconfirmedYellow,
                        textColor: .midnight,
                        icon: Image(ImagesAsset.warningBlack),
                        action: {
                            switch viewModel.actionDisplay {
                            case .email, .emailGet10GB:
                                router.navigate(to: .enterEmail)
                            case .setupAccountAndLogin, .setupAccount:
                                router.navigate(to: .signupGhost)
                            case .confirmEmail:
                                showConfirmEmailSheet = true
                            default:
                                break
                            }
                        }
                    )
                }

                if viewModel.actionDisplay == .setupAccountAndLogin || viewModel.actionDisplay == .setupAccount {
                    PreferencesActionButton(
                        title: TextsAsset.login,
                        backgroundColor: .midnight,
                        textColor: .white,
                        icon: nil,
                        action: {
                            router.navigate(to: .login)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.nightBlue)
        .overlay(routeLink)
        .edgesIgnoringSafeArea(.bottom)
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
        .sheet(isPresented: $showConfirmEmailSheet) {
            if #available(iOS 16.4, *) {
                router.createView(for: .confirmEmail)
                    .presentationDetents([PresentationDetent.fraction(0.65)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(24)
            } else if #available(iOS 16.0, *) {
                router.createView(for: .confirmEmail)
                    .presentationDetents([PresentationDetent.fraction(0.65)])
                    .presentationDragIndicator(.hidden)
            } else {
                router.createView(for: .confirmEmail)
            }
        }
    }

    @ViewBuilder
    private func categoryRows() -> some View {
        ForEach(viewModel.visibleItems) { item in
            if let index = viewModel.visibleItems.firstIndex(where: { $0.id == item.id }),
               !viewModel.shouldHideRow(index: index) {

                Button {
                    if index == 1 {
                        let dynamicRoute = viewModel.getDynamicRouteForAccountRow()
                        router.navigate(to: dynamicRoute)
                    } else if let route = item.routeID {
                        router.navigate(to: route)
                    } else if item == .logout {
                        viewModel.logout()
                    }
                } label: {
                    MenuCategoryRow(item: item)
                        .frame(height: 44)
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
