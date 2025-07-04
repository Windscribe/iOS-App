//
//  EmergencyConnectView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-02.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Combine

struct EmergencyConnectView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: EmergencyConnectViewModelImpl

    private let maxIphoneWidth: CGFloat = 430

    func getMaxWidth(for geometry: GeometryProxy) -> CGFloat {
        return min(geometry.size.width, maxIphoneWidth)
    }

    func getBottomPadding(for geometry: GeometryProxy) -> CGFloat {
        if deviceType == .iPadPortrait {
            return geometry.size.height * 0.24
        } else if deviceType == .iPadLandscape {
            return geometry.size.height * 0.12
        }
        return 24
    }

    func getTopSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        if deviceType == .iPadPortrait {
            return geometry.size.height * 0.24
        }
        return geometry.size.height * 0.12
    }

    init(viewModel: any EmergencyConnectViewModel) {
        guard let model = viewModel as? EmergencyConnectViewModelImpl else {
            fatalError("SignUpView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            PreferencesBaseView(isDarkMode: $viewModel.isDarkMode) {
                VStack(spacing: 24) {
                    headerSection

                    Spacer()

                    ZStack(alignment: .top) {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: getTopSpacerHeight(for: geometry))

                            Image(ImagesAsset.Welcome.emergencyConnectIcon)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                            Text(TextsAsset.connect)
                                .font(.bold(.title1))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(.from(.iconColor, viewModel.isDarkMode))

                            descriptionSection

                            Spacer()
                        }

                        if viewModel.connectionState == .connecting {
                            VStack(spacing: 4) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .padding(.top, 12)

                                Text(TextsAsset.connecting.uppercased())
                                    .font(.semiBold(.callout))
                                    .dynamicTypeSize(dynamicTypeRange)
                                    .foregroundColor(.welcomeButtonTextColor)
                                    .padding(.top, 4)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, geometry.size.height * 0.4)
                        }
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button(action: {
                            viewModel.connectButtonTapped()
                        }, label: {
                            Text(connectButtonText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.loginRegisterEnabledButtonColor)
                                .foregroundColor(.from(.actionBackgroundColor, viewModel.isDarkMode))
                                .font(.bold(.title3))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        })
                        .frame(maxWidth: getMaxWidth(for: geometry))

                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(TextsAsset.cancel)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.welcomeButtonTextColor)
                                .font(.bold(.title3))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        })
                        .frame(maxWidth: getMaxWidth(for: geometry))
                    }
                    .padding(.bottom, getBottomPadding(for: geometry))
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    viewModel.appEnteredForeground()
                }
            }
        }
    }

    private var connectButtonText: String {
        switch viewModel.connectionState {
        case .connected, .connecting:
            return TextsAsset.disconnect
        case .disconnected:
            return TextsAsset.connect
        case .disconnecting:
            return TextsAsset.disconnecting
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        switch viewModel.connectionState {
        case .connected:
            Text(TextsAsset.connectedDescription)
                .font(.text(.body))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.welcomeButtonTextColor)
                .multilineTextAlignment(.center)
        default:
            Text(TextsAsset.eConnectDescription)
                .font(.text(.body))
                .dynamicTypeSize(dynamicTypeRange)
                .foregroundColor(.welcomeButtonTextColor)
                .multilineTextAlignment(.center)
        }
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            if !(deviceType == .iPadLandscape || deviceType == .iPadPortrait) {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(.title))
                        .foregroundColor(.from(.iconColor, viewModel.isDarkMode))
                })
            }
        }
    }
}
