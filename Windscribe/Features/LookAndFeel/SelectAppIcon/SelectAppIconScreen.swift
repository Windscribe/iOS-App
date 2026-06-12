//
//  SelectAppIconScreen.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//
import SwiftUI

@available(iOS 17.0, *)
struct SelectAppIconScreen: View {
    @Environment(\.preferencesReading) private var preferencesReading
    @Environment(\.preferencesWriting) private var preferencesWriting
    @Environment(\.logger) private var logger

    var body: some View {
        let viewModel = SelectAppIconViewModel(
            logger: logger,
            preferencesReading: preferencesReading,
            preferencesWriting: preferencesWriting
        )

        SelectAppIconContentView(viewModel: viewModel)
            .navigationTitle(TextsAsset.LookFeel.discreetAppIconTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17.0, *)
private struct SelectAppIconContentView: View {
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @State private var viewModel: SelectAppIconViewModel

    init(viewModel: SelectAppIconViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BaseContentView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(IconSection.allCases, id: \.self) { section in
                        IconSectionView(
                            section: section,
                            icons: section.icons(from: viewModel.iconOptions),
                            selectedIcon: viewModel.selectedIcon,
                            onIconSelected: { icon in
                                viewModel.iconSelected(icon)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}
