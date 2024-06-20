//
//  SendDebugLogCompletedViewController.swift
//  Windscribe
//
//  Created by Thomas on 01/10/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit

protocol SendDebugLogCompletedVCDelegate: AnyObject {
    func sendDebugLogCompletedVCCanceled()
}

class SendDebugLogCompletedViewController: WSNavigationViewController {
    private let message = "Your debug log has been received. Please contact support if you want assistance with this issue.".localize()
    var viewModel: SendDebugLogCompletedViewModelType!

    weak var delegate: SendDebugLogCompletedVCDelegate?

    // MARK: - UI ELEMENTs
    private lazy var topImage: UIImageView = {
        let vw = UIImageView()
        vw.image = UIImage(named: ImagesAsset.checkCircleGreen)
        vw.contentMode = .scaleAspectFit
        vw.anchor(height: 86)
        return vw
    }()

    private lazy var subHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = message
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

    private lazy var contactSupportButton: WSButton = {
        let btn = WSButton(type: .normal,
                           size: .large,
                           text: TextsAsset.AutoModeFailedToConnectPopup.contactSupport,
                           isDarkMode: viewModel.isDarkMode)
        btn.addTarget(self, action: #selector(contactSupportButtonTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - CONFIGs
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindViews()
    }

    private func setup() {
        setupCloseButton()
        setupFillLayoutView()
        layoutView.stackView.spacing = 16
        layoutView.stackView.addArrangedSubviews([
            topImage,
            subHeaderLabel,
            contactSupportButton,
            cancelButton
        ])
        layoutView.stackView.setPadding(UIEdgeInsets(top: 54, left: 48, bottom: 16, right: 48))
        layoutView.stackView.setCustomSpacing(32, after: topImage)
        layoutView.stackView.setCustomSpacing(48, after: subHeaderLabel)
        layoutView.stackView.setCustomSpacing(32, after: contactSupportButton)
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] in
            setupViews(isDark: $0)
            subHeaderLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            let attribute = NSAttributedString(
                string: "Cancel".localize(),
                attributes: [NSAttributedString.Key.font: UIFont.bold(size: 16),
                             NSAttributedString.Key.foregroundColor: ThemeUtils.primaryTextColor50(isDarkMode: $0)]
            )
            cancelButton.setAttributedTitle(attribute, for: .normal)
        }).disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func cancelAction() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.sendDebugLogCompletedVCCanceled()
        }
    }

    @objc func contactSupportButtonTapped() {
        openLink(url: LinkProvider.getWindscribeLink(path: Links.helpMe))
    }
}
