//
//  View+WillDisappear.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

private struct WillDisappearHandler: UIViewControllerRepresentable {
    let onWillDisappear: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ViewWillDisappearViewController(onWillDisappear: onWillDisappear)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private class ViewWillDisappearViewController: UIViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear()
        }
    }
}

extension View {
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        background(WillDisappearHandler(onWillDisappear: perform))
    }
}
