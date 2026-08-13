//
//  EmergencyConnectScreen.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

/// Top-level navigation destination for the Neo Emergency Connect screen.
@available(iOS 17.0, *)
struct EmergencyConnectScreen: View {
    @Environment(\.vpnStateProviding) private var vpnStateProviding
    @Environment(\.emergencyConnecting) private var emergencyConnecting
    @Environment(\.logger) private var logger

    var body: some View {
        EmergencyConnectContentView(
            viewModel: EmergencyConnectScreenViewModel(
                vpnStateProviding: vpnStateProviding,
                emergencyConnecting: emergencyConnecting,
                logger: logger
            )
        )
    }
}

@available(iOS 17.0, *)
private struct EmergencyConnectContentView: View, ResponsivePopupLayoutProvider {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceType) private var deviceType
    @Environment(\.dynamicTypeLargeRange) private var dynamicTypeRange
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.lookAndFeel) private var lookAndFeel

    @State private var viewModel: EmergencyConnectScreenViewModel

    init(viewModel: EmergencyConnectScreenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindable = viewModel

        GeometryReader { geometry in
            let topSpacer = getTopSpacerHeight(for: geometry, deviceType: deviceType)
            let bottomPadding = getBottomPadding(for: geometry, deviceType: deviceType)
            let maxWidth = getMaxWidth(for: geometry)

            BaseContentView() {
                VStack(spacing: 24) {
                    headerSection

                    Spacer()

                    ZStack(alignment: .top) {
                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: topSpacer)

                            Image(ImagesAsset.Welcome.emergencyConnectIcon)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))

                            Text(TextsAsset.Welcome.emergencyConnectTitle)
                                .font(.bold(.title1))
                                .dynamicTypeSize(dynamicTypeRange)
                                .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))

                            descriptionSection
                                .frame(maxWidth: maxWidth)

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
                                .foregroundColor(.from(.actionBackgroundColor, lookAndFeel.isDarkMode))
                                .font(.bold(.title3))
                                .dynamicTypeSize(dynamicTypeRange)
                                .clipShape(Capsule())
                        })
                        .frame(maxWidth: maxWidth)

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
                        .frame(maxWidth: maxWidth)
                    }
                    .padding(.bottom, bottomPadding)
                }
                .padding()
                .dynamicTypeSize(dynamicTypeRange)
                .task {
                    await viewModel.startObservers()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        viewModel.appEnteredForeground()
                    }
                }
                .alert("Staging", isPresented: $bindable.isStagingAlertPresented) {
                    Button(TextsAsset.okay, role: .cancel) {}
                } message: {
                    Text("No Emergency Connect in Staging")
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
                        .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode))
                })
            }
        }
    }
}
