//
//  RatePopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class RatePopupViewController: BasePopUpViewController {
    @IBOutlet weak var buttonStackView: UIStackView!
    
    var rateButton = WSPillButton()
    var laterButton = WSPillButton()
    var goAwayButton = WSPillButton()
    
    var ruViewModel: RateUsPopupModelType!
    
    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViews()
    }
    
    //MARK: Setting up
    override func setup() {
        super.setup()
        view.addBlueGradientBackground()
        rateButton.setTitle(TextsAsset.RateUs.action, for: .normal)
        laterButton.setTitle(TextsAsset.RateUs.maybeLater, for: .normal)
        goAwayButton.setTitle(TextsAsset.RateUs.goAway, for: .normal)
        
        [rateButton, laterButton, goAwayButton].forEach { roundbutton in
            roundbutton.setup(withHeight: 96.0)
            buttonStackView.addArrangedSubview(roundbutton)
        }
        buttonStackView.addArrangedSubview(UIView())
    }
    
    private func bindViews() {
        rateButton.rx.primaryAction.bind { [self] in
            ruViewModel.setRateUsActionCompleted()
            guard let url = URL(string: "com.apple.TVAppStore://itunes.apple.com/app/windscribe-vpn/id1129435228?mt=8") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }.disposed(by: disposeBag)
        laterButton.rx.primaryAction.bind { [self] in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        goAwayButton.rx.primaryAction.bind { [self] in
            ruViewModel.setRateUsActionCompleted()
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}
