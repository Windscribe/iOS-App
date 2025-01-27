//
//  LocationPermissionDisclosureViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-09-14.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Swinject
import UIKit

protocol DisclosureAlertDelegate: AnyObject {
    func grantPermissionClicked()
    func openLocationSettingsClicked()
}

// swiftlint:disable next type_name
class LocationPermissionDisclosureViewController: WSUIViewController {
    var logger: FileLogger = Assembler.resolve(FileLogger.self)

    var backgroundView: UIView!
    var infoIcon: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var actionButton: UIButton!
    var cancelButton: UIButton!
    weak var delegate: DisclosureAlertDelegate?
    var denied: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Location Permission Popup View")
        addViews()
        addAutoLayoutConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    @objc func actionButtonTapped() {
        if denied {
            delegate?.openLocationSettingsClicked()
        } else {
            delegate?.grantPermissionClicked()
        }
        dismiss(animated: true, completion: nil)
    }

    @objc func cancelButtonTapped() {
        logger.logD(self, "Location Permission Popup cancelled")
        dismiss(animated: true, completion: nil)
    }
}
