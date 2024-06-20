//
//  RateUsPopupViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import StoreKit

class RateUsPopupViewController: WSUIViewController {

    var backgroundView: UIView!
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!
    var maybeLaterButton: UIButton!
    var goAwayButton: UIButton!

    var viewModel: RateUsPopupModelType!
    var logger: FileLogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Rate Us View")
        viewModel.setDate()
        self.addViews()
        self.addAutoLayoutConstraints()
    }

    @objc func actionButtonTapped() {
        viewModel.setRateUsActionCompleted()
        if (viewModel.getNativeRateUsDisplayCount() ?? 0) < 3 {
            SKStoreReviewController.requestReview()
            viewModel.increaseNativeRateUsPopupDisplayCount()
        } else {
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/1129435228") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func goAwayButtonTapped() {
        viewModel.setRateUsActionCompleted()
        self.dismiss(animated: true, completion: nil)
    }

}
