//
//  NewsFeedDetailView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct NewsFeedDetailView: View {
    let item: NewsFeedDataModel
    let didTapExpand: () -> Void
    let didTapAction: (ActionLinkModel) -> Void

    @Binding var isDarkMode: Bool
    @State private var showRotation: Bool

    init(item: NewsFeedDataModel,
         didTapExpand: @escaping () -> Void,
         didTapAction: @escaping (ActionLinkModel) -> Void,
         isDarkMode: Binding<Bool>) {
        self.item = item
        self.didTapExpand = didTapExpand
        self.didTapAction = didTapAction
        self._isDarkMode = isDarkMode
        _showRotation = State(initialValue: item.expanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Text(item.title)
                            .font(.medium(.callout))
                            .foregroundColor(.from(.titleColor, isDarkMode).opacity(item.expanded ? 1 : 0.8))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.down")
                            .foregroundColor(item.expanded ? .from(.iconColor, isDarkMode) : .gray.opacity(0.8))
                            .rotationEffect(.degrees(showRotation ? 180 : 0))
                            .animation(.easeInOut(duration: 0.3), value: showRotation)
                    }

                    Text(DateFormatter.customNoticeFormat.string(from: item.date))
                        .font(.regular(.footnote))
                        .foregroundColor(.gray.opacity(0.8))

                    // Description (Hidden for Collapsed State)
                    if item.expanded {
                        Text(item.description)
                            .font(.regular(.callout))
                            .foregroundColor(.from(.titleColor, isDarkMode).opacity(item.expanded ? 1 : 0.8))
                            .padding(.top, 4)
                    }

                    if item.expanded, let actionLink = item.actionLink {
                        Button(
                            action: {
                                didTapAction(actionLink)
                            }, label: {
                                Text(actionLink.title)
                                    .foregroundColor(isDarkMode ? .newsFeedButtonActionColor : .green)
                                    .font(.regular(.footnote))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Color.newsFeedButtonActionColor.opacity(isDarkMode ? 0.05: 0.35)
                                    )
                                    .clipShape(Capsule())
                            }
                        )
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .onChange(of: item.expanded) { isExpanded in
                showRotation = isExpanded
            }
            .onTapGesture {
                didTapExpand()
            }
        }
    }
}
