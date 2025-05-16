//
//  AboutSettingsView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct AboutSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: AboutSettingsViewModelImpl

    init(viewModel: any AboutSettingsViewModel) {
        guard let model = viewModel as? AboutSettingsViewModelImpl else {
            fatalError("AboutSettingsView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.entries) { item in
                    Button {
                        viewModel.entrySelected(item)
                    } label: {
                        MenuCategoryRow(item: item)
                            .frame(height: 48)
                    }
                    if item != viewModel.entries.last {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 2)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.nightBlue)
        .dynamicTypeSize(dynamicTypeRange)
        .sheet(item: $viewModel.safariURL) { url in
            SafariView(url: url)
        }
        .navigationTitle(TextsAsset.About.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
