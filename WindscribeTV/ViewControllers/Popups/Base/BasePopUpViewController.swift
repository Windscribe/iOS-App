//
//  BasePopUpViewController.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 12/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class BasePopUpViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var mainStackView: UIStackView!

    let disposeBag = DisposeBag()
    var viewModel: BasePopupViewModelType?, logger: FileLogger!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        guard let viewModel = viewModel, let type = viewModel.type else { return }
        logger.logD(self, "Displaying \(type.title) Pop up.")
        titleLabel?.text = type.title
        titleLabel?.font = UIFont.bold(size: 92)
        titleLabel?.textColor = .white.withAlphaComponent(0.15)

        headerLabel.text = type.header
        headerLabel.font = UIFont.bold(size: 62)
        headerLabel.textColor = .white

        bodyLabel.text = type.body
        bodyLabel.font = UIFont.regular(size: 42)
        bodyLabel.textColor = .white.withAlphaComponent(0.4)
    }
}
