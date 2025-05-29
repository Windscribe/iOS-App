//
//  ConnectionSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ConnectionSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: ConnectionSettingsViewModelImpl

    init(viewModel: any ConnectionSettingsViewModel) {
        guard let model = viewModel as? ConnectionSettingsViewModelImpl else {
            fatalError("ConnectionSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ZStack {
            Color.nightBlue
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.entries, id: \.self) { entry in
                        MenuEntryView(item: entry, action: { actionType in
                            viewModel.entrySelected(entry, action: actionType)
                        })
                    }
                }
                .padding(.top, 8)
            }
            .dynamicTypeSize(dynamicTypeRange)
        }
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
        .navigationTitle(TextsAsset.Connection.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
