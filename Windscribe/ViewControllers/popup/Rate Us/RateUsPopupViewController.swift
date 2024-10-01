import UIKit
import SwiftUI

class RateUsPopupViewController: WSUIViewController {
    var viewModel: RateUsPopupModelType!

    override func viewDidLoad() {

        showRateUsPopup()
    }

    @objc func showRateUsPopup() {
        if #available(iOS 16.0, *) {
            view.backgroundColor = .red

            let swiftUIView = RateUsPopupView(viewModel: viewModel, onDismiss: {
                self.dismiss(animated: true, completion: nil) // Dismiss the view controller
            })

            let hostingController = UIHostingController(rootView: swiftUIView)

            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            hostingController.didMove(toParent: self)

        }
    }
}
