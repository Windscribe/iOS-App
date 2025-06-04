//
//  HelpInfoCardView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-29.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI

struct HelpInfoCardView: View {
    let isDarkMode: Bool
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.iconColor, isDarkMode))

                    Text(title)
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .font(.bold(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(ImagesAsset.serverWhiteRightArrow)
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.4))
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.regular(.footnote))
                        .foregroundColor(.from(.titleColor, isDarkMode).opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .background(Color.from(.backgroundColor, isDarkMode))
            .cornerRadius(12)
        }
    }
}

struct HelpExpandableListView: View {
    let isDarkMode: Bool
    let icon: String
    let title: String
    let subtitle: String
    let subItems: [(title: String, urlString: String)]
    let onSubItemTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.iconColor, isDarkMode))

                    Text(title)
                        .font(.bold(.callout))
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)

                Text(subtitle)
                    .font(.regular(.footnote))
                    .foregroundColor(.from(.titleColor, isDarkMode).opacity(0.6))
                    .padding(.horizontal, 14)

                Rectangle()
                    .fill(Color.from(.separatorColor, isDarkMode))
                    .frame(height: 1)
            }
            .padding(.top, 14)

            ForEach(subItems.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color.from(.separatorColor, isDarkMode))
                        .frame(height: 1)
                }

                Button(action: {
                    onSubItemTap(subItems[index].urlString)
                }, label: {
                    HStack {
                        Text(subItems[index].title)
                            .font(.regular(.callout))
                            .foregroundColor(.from(.titleColor, isDarkMode).opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(ImagesAsset.serverWhiteRightArrow)
                            .renderingMode(.template)
                            .frame(width: 16, height: 16)
                            .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.4))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                })
            }
        }
        .background(Color.from(.backgroundColor, isDarkMode))
        .cornerRadius(12)
    }
}

struct HelpNavigationRowView: View {
    let isDarkMode: Bool
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.iconColor, isDarkMode))

                    Text(title)
                        .font(.bold(.callout))
                        .foregroundColor(.from(.titleColor, isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(ImagesAsset.serverWhiteRightArrow)
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.4))
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.regular(.footnote))
                        .foregroundColor(.from(.titleColor, isDarkMode).opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .background(Color.from(.backgroundColor, isDarkMode))
            .cornerRadius(12)
        }
    }
}

struct HelpSendDebugLogView: View {
    let isDarkMode: Bool
    let icon: String
    let title: String
    let progressText: String
    let sentText: String
    let status: HelpLogStatus
    let action: () -> Void

    var body: some View {
        Button(action: {
            if case .idle = status {
                action()
            }
        }, label: {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(.from(.iconColor, isDarkMode))

                Text(rowTitle)
                    .font(.bold(.callout))
                    .foregroundColor(.from(.titleColor, isDarkMode))
                    .frame(maxWidth: .infinity, alignment: .leading)

                rightAccessory
            }
            .padding(14)
            .background(Color.from(.backgroundColor, isDarkMode))
            .cornerRadius(12)
        })
        .disabled(!isEnabled)
    }

    private var rowTitle: String {
        switch status {
        case .sending:
            return "\(progressText)..."
        default:
            return title
        }
    }

    @ViewBuilder
    private var rightAccessory: some View {
        switch status {
        case .sending:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.75)

        case .success:
            Text(sentText)
                .font(.regular(.footnote))
                .foregroundColor(.from(.titleColor, isDarkMode).opacity(0.6))

        default:
            Image(ImagesAsset.serverWhiteRightArrow)
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundColor(.from(.iconColor, isDarkMode).opacity(0.4))
        }
    }

    private var isEnabled: Bool {
        switch status {
        case .idle, .failure:
            return true
        default:
            return false
        }
    }
}
