//
//  MenuCategoryRow.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct MenuCategoryRow: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let item: any MenuCategoryRowType
    let title: String

    init(item: any MenuCategoryRowType) {
        self.item = item
        self.title = item.title
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(item.backgroundTintColor(lookAndFeel.isDarkMode))
                .cornerRadius(12)
            HStack(spacing: 12) {
                if let imageName = item.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(item.tintColor(lookAndFeel.isDarkMode))
                }
                if let actionImageName = item.actionImageName {
                    Text(title)
                        .foregroundColor(item.tintColor(lookAndFeel.isDarkMode))
                        .font(.medium(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(actionImageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 13, height: 13)
                        .foregroundColor(item.actionTintColor(lookAndFeel.isDarkMode))
                } else {
                    Text(title)
                        .foregroundColor(item.tintColor(lookAndFeel.isDarkMode))
                        .font(.medium(.callout))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
