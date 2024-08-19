//
//  ServerListViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 12/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class ServerListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didMove(toParent parent: UIViewController?) {
        print("did move")
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let vc = self.presentingViewController as? MainViewController {
            vc.isFromServer = true
        }
    }

}
