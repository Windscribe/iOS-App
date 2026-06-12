//
//  SafariView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-18.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .from(.iconColor, lookAndFeel.isDarkMode)
        safariVC.preferredBarTintColor = .from(.backgroundColor, lookAndFeel.isDarkMode)

        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
