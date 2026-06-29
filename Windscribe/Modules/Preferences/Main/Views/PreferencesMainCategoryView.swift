//
//  PreferencesMainCategoryView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

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
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 14) {
                        categoryRows()
                    }
                    .padding(.top, 8)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.actionButtons, id: \.id) { actionType in
                        PreferencesActionButton(
                            actionType: actionType,
                            action: { handlePrimaryAction(for: actionType) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(routeLink)
        .edgesIgnoringSafeArea(.bottom)
        .dynamicTypeSize(dynamicTypeRange)
        .withRouter(router)
        .sheet(isPresented: $showConfirmEmailSheet) {
            if #available(iOS 16.4, *) {
                confirmEmailSheetContent
                    .presentationDetents([PresentationDetent.fraction(0.65)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(24)
                    .presentationBackground {
                        Color.from(.screenBackgroundColor, viewModel.isDarkMode)
                            .padding(.bottom, -1000) // Extend background to cover peek area
                    }
            } else if #available(iOS 16.0, *) {
                confirmEmailSheetContent
                    .presentationDetents([PresentationDetent.fraction(0.65)])
                    .presentationDragIndicator(.hidden)
            } else {
                confirmEmailSheetContent
            }
        }
        .onWillDisappear {
            viewModel.actionSelected()
        }
    }

    private func handlePrimaryAction(for actionType: PreferencesAction) {
        viewModel.actionSelected()
        switch actionType {
        case .email, .emailGet10GB:
            router.navigate(to: .enterEmail)
        case .setupAccountAndLogin, .setupAccount:
            router.navigate(to: .signupGhost)
        case .confirmEmail:
            showConfirmEmailSheet = true
        case .login:
            router.navigate(to: .login)
        }
    }

    @ViewBuilder
    private var confirmEmailSheetContent: some View {
        if #available(iOS 17.0, *) {
            ConfirmEmailScreen(
                openEnterEmail: {
                    showConfirmEmailSheet = false
                    router.navigate(to: .enterEmail)
                },
                onDismiss: {
                    showConfirmEmailSheet = false
                }
            )
        } else {
            Assembler.resolve(ConfirmEmailView.self)
        }
    }

    @ViewBuilder
    private func categoryRows() -> some View {
        ForEach(viewModel.visibleItems, id: \.self) { item in
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
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var routeDestination: some View {
        if let route = router.activeRoute {
            router.createView(for: route)
        } else {
            EmptyView()
        }
    }
}
