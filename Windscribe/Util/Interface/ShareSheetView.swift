//
//  ShareSheetView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
