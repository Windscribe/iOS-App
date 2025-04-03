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
    @StateObject private var viewModel: EmergencyConnectViewModelImpl

    private let dynamicTypeRange = (...DynamicTypeSize.large)

    init(viewModel: any EmergencyConnectViewModel) {
        guard let model = viewModel as? EmergencyConnectViewModelImpl else {
            fatalError("SignUpView must be initialized properly")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                headerSection

                Spacer()

                ZStack(alignment: .top) {
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: geometry.size.height * 0.12)

                        Image(ImagesAsset.Welcome.emergencyConnectIcon)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)

                        Text(TextsAsset.connect)
                            .font(.bold(.title1))
                            .dynamicTypeSize(dynamicTypeRange)
                            .foregroundColor(.white)

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

                VStack(spacing: 24) {
                    Button(action: {
                        viewModel.connectButtonTapped()
                    }, label: {
                        Text(connectButtonText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.loginRegisterEnabledButtonColor)
                            .foregroundColor(.black)
                            .font(.bold(.title3))
                            .dynamicTypeSize(dynamicTypeRange)
                            .clipShape(Capsule())
                    })

                    Button(TextsAsset.cancel) {
                        dismiss()
                    }
                    .foregroundColor(.welcomeButtonTextColor)
                    .font(.bold(.title3))
                    .dynamicTypeSize(dynamicTypeRange)
                }
                .padding(.bottom, 24)
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                viewModel.appEnteredForeground()
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
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(.title))
                    .foregroundColor(.white)
            })
        }
    }
}
