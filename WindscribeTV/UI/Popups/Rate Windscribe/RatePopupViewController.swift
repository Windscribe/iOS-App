//
//  RatePopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import UIKit

class RatePopupViewController: BasePopUpViewController {
    @IBOutlet var buttonStackView: UIStackView!

    var rateButton = WSPillButton()
    var laterButton = WSPillButton()
    var goAwayButton = WSPillButton()

    var ruViewModel: RateUsPopupModelType!
    private var cancellables = Set<AnyCancellable>()

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD("RatePopupViewController", "Displaying Rate Us popup View")
        bindViews()
    }

    // MARK: Setting up

    override func setup() {
        super.setup()
        view.addBlueGradientBackground()
        rateButton.setTitle(TextsAsset.RateUs.action, for: .normal)
        laterButton.setTitle(TextsAsset.RateUs.maybeLater, for: .normal)
        goAwayButton.setTitle(TextsAsset.RateUs.goAway, for: .normal)

        for roundbutton in [rateButton, laterButton, goAwayButton] {
            roundbutton.setup(withHeight: 96.0)
            buttonStackView.addArrangedSubview(roundbutton)
        }
        buttonStackView.addArrangedSubview(UIView())
    }

    private func bindViews() {
        rateButton.wasSelected
            .sink { [self] _ in
                logger.logD("RatePopupViewController", "Rate us button pressed.")
                ruViewModel.setRateUsActionCompleted()
                guard let url = URL(string: "com.apple.TVAppStore://itunes.apple.com/app/windscribe-vpn/id1129435228?mt=8") else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            .store(in: &cancellables)
        laterButton.wasSelected
            .sink { [self] _ in
                logger.logD("RatePopupViewController", "Latter button pressed.")
                self.dismiss(animated: true, completion: nil)
            }
            .store(in: &cancellables)
        goAwayButton.wasSelected
            .sink { [self] _ in
                logger.logD("RatePopupViewController", "Go away button pressed.")
                ruViewModel.setRateUsActionCompleted()
                self.dismiss(animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }
}
