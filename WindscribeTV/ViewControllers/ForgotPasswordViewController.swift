//
//  ForgotPasswordViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 31/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    

    private func setupUI() {
        if let backgroundImage = UIImage(named: "WelcomeBackground.png") {
            self.view.backgroundColor = UIColor(patternImage: backgroundImage)
        } else {
            self.view.backgroundColor = .blue
        }
        welcomeLabel.font = UIFont.bold(size: 60)
        infoLabel.font = UIFont.text(size: 30)
        backButton.titleLabel?.font = UIFont.text(size: 35)

        backButton.setBackgroundImage(UIImage.imageWithColor(.clear), for: .focused)

    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

}
