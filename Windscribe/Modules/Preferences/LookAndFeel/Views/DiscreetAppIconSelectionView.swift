//
//  DiscreetAppIconSelectionView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2026-01-16.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct DiscreetAppIconSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dynamicTypeXLargeRange) private var dynamicTypeRange

    @StateObject private var viewModel: DiscreetAppIconSelectionViewModelImpl

    init(viewModel: any DiscreetAppIconSelectionViewModel) {
        guard let model = viewModel as? DiscreetAppIconSelectionViewModelImpl else {
            fatalError("DiscreetAppIconSelectionView must be initialized properly with ViewModelImpl")
        }

        _viewModel = StateObject(wrappedValue: model)
    }

    var body: some View {
        PreferencesBaseView(isDarkMode: $viewModel.isDarkMode, useHapticFeedback: false) {
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
        .dynamicTypeSize(dynamicTypeRange)
        .navigationTitle(TextsAsset.LookFeel.discreetAppIconTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.actionSelected()
        }
    }
}

struct IconSectionView: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let section: IconSection
    let icons: [DiscreetAppIconType]
    let selectedIcon: DiscreetAppIconType
    let onIconSelected: (DiscreetAppIconType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(section.title)
                .font(.semiBold(.footnote))
                .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))

            // Section content
            VStack(spacing: 0) {
                ForEach(Array(icons.enumerated()), id: \.element) { index, icon in
                    IconRowView(
                        icon: icon,
                        isSelected: selectedIcon == icon,
                        isDarkMode: lookAndFeel.isDarkMode,
                        showSeparator: index < icons.count - 1,
                        action: {
                            onIconSelected(icon)
                        }
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
            )
        }
    }
}

struct IconRowView: View {
    let icon: DiscreetAppIconType
    let isSelected: Bool
    let isDarkMode: Bool
    let showSeparator: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(icon.iconImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)

                // Icon name
                Text(icon.displayName)
                    .font(.medium(.body))
                    .foregroundColor(.from(.titleColor, isDarkMode))

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.seaGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.from(.backgroundColor, isDarkMode))
        }
        .buttonStyle(PlainButtonStyle())

        if showSeparator {
            Divider()
                .background(Color.from(.separatorColor, isDarkMode))
                .padding(.leading, 88)
        }
    }
}
