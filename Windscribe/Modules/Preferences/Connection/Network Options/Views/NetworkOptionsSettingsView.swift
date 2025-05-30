//
//  NetworkSecurityView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct NetworkSecurityView: View {
    @StateObject private var viewModel: NetworkOptionsSecurityViewModelImpl

    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    init(viewModel: any NetworkOptionsSecurityViewModel) {
        guard let model = viewModel as? NetworkOptionsSecurityViewModelImpl else {
            fatalError("NetworkSecurityView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        Text(TextsAsset.NetworkSecurity.header)
                            .foregroundColor(.infoGrey)
                            .multilineTextAlignment(.leading)
                            .font(.regular(.footnote))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                    .padding(.horizontal, 16)
                    if let entry = viewModel.autoSecureEntry {
                        MenuEntryView(item: entry, action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                    if let entry = viewModel.currentNetworkEntry {
                        VStack(spacing: 0) {
                            Text(TextsAsset.NetworkSecurity.currentNetwork.uppercased())
                                .font(.caption)
                                .foregroundColor(.infoGrey)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MenuEntryView(item: entry, action: { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            })
                        }
                    }
                    if let entry = viewModel.networkListEntry {
                        VStack(spacing: 0) {
                            Text(TextsAsset.NetworkSecurity.otherNetwork.uppercased())
                                .font(.caption)
                                .foregroundColor(.infoGrey)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MenuEntryView(item: entry, action: { actionType in
                                viewModel.entrySelected(entry, action: actionType)
                            })
                        }
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .navigationTitle(TextsAsset.NetworkSecurity.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
