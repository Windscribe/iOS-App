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
        HStack(spacing: 12) {
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(item.tintColor)
            }
            Text(item.title)
                .foregroundColor(.white)
                .font(.bold(.callout))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionImageName = item.actionImageName {
                Image(actionImageName)
                    .renderingMode(.template)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
    }
}
