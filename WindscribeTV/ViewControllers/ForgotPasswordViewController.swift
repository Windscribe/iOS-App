//
//  ForgotPasswordViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 31/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {
    @IBOutlet var infoLabel: UILabel!

    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var backButton: UIButton!

    var logger: FileLogger!
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Forgotten Password Screen.")
        setupUI()
        setupLocalized()
        // Do any additional setup after loading the view.
    }

    private func setupUI() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            view.backgroundColor = .blue
        }
        welcomeLabel.font = UIFont.bold(size: 60)
        infoLabel.font = UIFont.text(size: 30)
        backButton.titleLabel?.font = UIFont.text(size: 35)

        backButton.setBackgroundImage(UIImage.imageWithColor(.clear), for: .focused)
    }

    @IBAction func backAction(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    func setupLocalized() {
        welcomeLabel.text = TextsAsset.slogan
        infoLabel.text = TextsAsset.TVAsset.forgotPasswordInfo
        backButton.titleLabel?.text = TextsAsset.back
    }
}
