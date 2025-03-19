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

    @State private var showRotation: Bool

    init(item: NewsFeedDataModel,
         didTapExpand: @escaping () -> Void,
         didTapAction: @escaping (ActionLinkModel) -> Void) {
        self.item = item
        self.didTapExpand = didTapExpand
        self.didTapAction = didTapAction
        _showRotation = State(initialValue: item.expanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 12) {
                if !item.readStatus {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Text(item.title)
                            .font(.medium(.callout))
                            .foregroundColor(.white.opacity(item.expanded ? 1 : 0.8))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray.opacity(0.8))
                            .rotationEffect(.degrees(showRotation ? 180 : 0))
                            .animation(.easeInOut(duration: 0.3), value: showRotation)
                    }
                    // Description (Hidden for Collapsed State)
                    if item.expanded {
                        Text(item.description)
                            .font(.regular(.callout))
                            .foregroundColor(.white.opacity(item.expanded ? 1 : 0.8))
                            .padding(.top, 4)
                    }

                    if item.expanded, let actionLink = item.actionLink {
                        Button(
                            action: {
                                didTapAction(actionLink)
                            }, label: {
                                Text(actionLink.title)
                                    .foregroundColor(.newsFeedButtonActionColor)
                                    .font(.regular(.footnote))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        Color.newsFeedButtonActionColor.opacity(0.05)
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
            .background(item.expanded
                        ? Color.newsFeedDetailExpandedBackgroundColor
                        : Color.newsFeedDetailBackgroundColor)
            .onChange(of: item.expanded) { isExpanded in
                showRotation = isExpanded
            }
            .onTapGesture {
                didTapExpand()
            }
        }
    }
}
