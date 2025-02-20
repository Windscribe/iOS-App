//
//  PopUpMaintenanceLocationVC.swift
//  Windscribe
//
//  Created by innmac on 28/12/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class PopUpMaintenanceLocationVC: WSNavigationViewController {
    // MARK: - PROPERTIES

    var viewModel: PopUpMaintenanceLocationModelType!

    // MARK: - UI ELEMENTs

    private lazy var topImage: UIImageView = {
        let vw = UIImageView()
        vw.contentMode = .scaleAspectFit
        vw.setDimensions(height: 130, width: 94)
        return vw
    }()

    private lazy var headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 21)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var subHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.alpha = 0.5
        lbl.font = UIFont.text(size: 16)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return btn
    }()

    private lazy var checkStatusButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(checkStatusAction), for: .touchUpInside)
        btn.backgroundColor = .seaGreen
        btn.makeHeightAnchor(equalTo: 48)
        btn.layer.cornerRadius = 24
        return btn
    }()

    // MARK: - CONFIGs

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
    }

    private func setup() {
        backButton.isHidden = true
        setupFillLayoutView()
        layoutView.stackView.spacing = 16
        layoutView.stackView.axis = .vertical
        layoutView.stackView.addArrangedSubviews([
            topImage,
            headerLabel,
            subHeaderLabel,
            checkStatusButton,
            cancelButton
        ])
        view.backgroundColor = UIColor.midnight
        view.layer.opacity = 0.97
        layoutView.stackView.setPadding(UIEdgeInsets(top: 54, left: 48, bottom: 16, right: 48))
        layoutView.stackView.setCustomSpacing(32, after: topImage)
        layoutView.stackView.setCustomSpacing(32, after: subHeaderLabel)
        layoutView.stackView.setCustomSpacing(32, after: checkStatusButton)
    }

    private func bindViews() {
        viewModel.topImageName.subscribe(onNext: { [self] in
            topImage.image = UIImage(named: $0)
        }).disposed(by: disposeBag)
        viewModel.headerLabelTitle.subscribe(onNext: { [self] in
            headerLabel.text = $0
        }).disposed(by: disposeBag)
        viewModel.subHeaderLabelTitle.subscribe(onNext: { [self] in
            subHeaderLabel.text = $0
        }).disposed(by: disposeBag)
        viewModel.cancelButtonTitle.subscribe(onNext: { title in
            let attributeString = NSAttributedString(
                string: title,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5),
                             .font: UIFont.text(size: 16)]
            )
            self.cancelButton.setAttributedTitle(attributeString, for: .normal)
        }).disposed(by: disposeBag)
        viewModel.checkStatusButtonTitle.subscribe(onNext: { title in
            let attributeString = NSAttributedString(
                string: title,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.midnight,
                             .font: UIFont.text(size: 16)]
            )
            self.checkStatusButton.setAttributedTitle(attributeString, for: .normal)
        }).disposed(by: disposeBag)
        viewModel.isDarkMode.subscribe(onNext: { [self] in
            self.headerLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.subHeaderLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc private func cancelAction() {
        viewModel.cancel(vc: self)
    }

    @objc private func checkStatusAction() {
        viewModel.checkStatusAction(vc: self)
    }
}
