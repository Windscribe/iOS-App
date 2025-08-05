import SwiftUI

struct ShakeForDataMainView: View, ResponsivePopupLayoutProvider {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ShakeForDataMainViewModelImpl
    @StateObject var router: ShakeForDataNavigationRouter

    init(viewModel: any ShakeForDataMainViewModel, router: ShakeForDataNavigationRouter) {
        guard let model = viewModel as? ShakeForDataMainViewModelImpl else {
            fatalError("ShakeForDataMainView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
        _router = StateObject(wrappedValue: router)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)

            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacer)

                    // Phone image with shake animation
                    Image(ImagesAsset.ShakeForData.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                    // Title
                    Text(TextsAsset.ShakeForData.title)
                        .font(.bold(.title1))
                        .foregroundColor(Color.from(.titleColor, viewModel.isDarkMode))
                        .padding(.bottom, 24)

                    // Description
                    Text(TextsAsset.ShakeForData.popupDescription)
                        .font(.text(.subheadline))
                        .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 48)

                    // Start Shaking Button
                    Button {
                        router.navigate(to: .shakeGame)
                    } label: {
                        Text(TextsAsset.ShakeForData.popupAction)
                            .font(.bold(.title3))
                            .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.from(.allowedColor(isEnabled: true), viewModel.isDarkMode))
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 44)
                    .padding(.bottom, 32)

                    // Bottom buttons
                    VStack(spacing: 24) {
                        Button {
                            router.dismiss()
                        } label: {
                            Text(TextsAsset.ShakeForData.popupCancel)
                                .font(.bold(.title3))
                                .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                        }

                        Rectangle()
                            .fill(Color.from(.infoColor, viewModel.isDarkMode))
                            .frame(height: 1)
                            .padding(.horizontal, 32)

                        Button {
                            router.navigate(to: .leaderboard)
                        } label: {
                            Text(TextsAsset.ShakeForData.popupViewLeaderboard)
                                .font(.bold(.title3))
                                .foregroundColor(Color.from(.infoColor, viewModel.isDarkMode))
                        }
                    }
                    .padding(.bottom, bottomPadding)
                    Spacer()
                }
            }
            .overlay(routeLink)
            .dynamicTypeSize(dynamicTypeRange)
            .withRouter(router)
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
}
