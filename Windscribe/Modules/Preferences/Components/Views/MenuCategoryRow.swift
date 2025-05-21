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

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(item.tintColor.opacity(0.05))
                .cornerRadius(12)
            HStack(spacing: 12) {
                if let imageName = item.imageName {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(item.tintColor)
                }
                if let actionImageName = item.actionImageName {
                    Text(item.title)
                        .foregroundColor(item.tintColor)
                        .font(.regular(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(actionImageName)
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(item.tintColor.opacity(0.4))
                } else {
                    Text(item.title)
                        .foregroundColor(item.tintColor)
                        .font(.regular(.callout))
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.horizontal, 16)
    }
}
