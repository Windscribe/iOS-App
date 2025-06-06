//
//  MenuCategoryRow.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct MenuCategoryRow: View {
    let item: any MenuCategoryRowType
    let isDarkMode: Bool
    let title: String

    init(item: any MenuCategoryRowType, isDarkMode: Bool) {
        self.item = item
        self.isDarkMode = isDarkMode
        self.title = item.title
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(item.backgroundTintColor(isDarkMode))
                .cornerRadius(12)
            HStack(spacing: 12) {
                if let imageName = item.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(item.tintColor(isDarkMode))
                }
                if let actionImageName = item.actionImageName {
                    Text(title)
                        .foregroundColor(item.tintColor(isDarkMode))
                        .font(.regular(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(actionImageName)
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(item.tintColor(isDarkMode).opacity(0.4))
                } else {
                    Text(title)
                        .foregroundColor(item.tintColor(isDarkMode))
                        .font(.regular(.callout))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 16)
    }
}
