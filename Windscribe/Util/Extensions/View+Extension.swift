//
//  View+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit

extension View {
    func getPresentingController(_ action: @escaping (UIViewController?) -> Void) -> some View {
        background(
            PresentingControllerFinder(action: action)
                .frame(width: 0, height: 0)
        )
    }
}

private struct PresentingControllerFinder: UIViewControllerRepresentable {
    let action: (UIViewController?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            self.action(controller.view.window?.rootViewController?.topMostViewController())
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
