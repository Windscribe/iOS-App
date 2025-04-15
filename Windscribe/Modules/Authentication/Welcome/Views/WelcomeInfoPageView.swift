//
//  WelcomeInfoPageView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-20.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

// MARK: - Info Page with Image and Text

struct WelcomeInfoPageView: View {

    @Environment(\.dynamicTypeRange) private var dynamicTypeRange

    let imageName: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 140, maxHeight: 140)

            Text(text)
                .font(.light(.title1))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
        }
        .dynamicTypeSize(dynamicTypeRange)
    }
}

// MARK: - Custom Page Indicator

struct PageIndicator: View {

    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    PageIndicator(currentPage: 2)
}

#Preview {
    TabView(selection: .constant(1)) {
        ForEach(0..<4, id: \.self) { index in
            WelcomeInfoPageView(imageName: "welcome-info-tab-1", text: "Lorem ipsum dolor sit amet")
            .tag(index)
        }
    }
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    .frame(height: 300)
}
