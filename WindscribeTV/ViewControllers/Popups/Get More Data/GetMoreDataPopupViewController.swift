//
//  GetMoreDataPopupViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 20/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class GetMoreDataPopupViewController: BasePopUpViewController {
    var router: HomeRouter!
    var signupRouter: SignupRouter!
    
    var signUpButton = WSPillButton()
    var getProButton = WSPillButton()
    
    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViews()
    }
    
    //MARK: Setting up
    override func setup() {
        super.setup()
        signUpButton.setTitle(TextsAsset.signUp, for: .normal)
        getProButton.setTitle("Get Pro - Unlimited".uppercased(), for: .normal)
        
        [signUpButton, getProButton].forEach { roundbutton in
            roundbutton.setup(withHeight: 96.0)
            mainStackView.addArrangedSubview(roundbutton)
        }
        mainStackView.addArrangedSubview(UIView())
    }
    
    private func bindViews() {
        signUpButton.rx.primaryAction.bind { [self] in
            signupRouter.routeTo(to: .signup(claimGhostAccount: false), from: self)
        }.disposed(by: disposeBag)
        getProButton.rx.primaryAction.bind { [self] in
            router.routeTo(to: .upgrade, from: self)
        }.disposed(by: disposeBag)
    }
}
