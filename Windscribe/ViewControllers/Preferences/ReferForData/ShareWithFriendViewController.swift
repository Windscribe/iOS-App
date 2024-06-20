//
//  ShareWithFriendViewController.swift
//  Windscribe
//
//  Created by Thomas on 16/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class ShareWithFriendViewController: WSNavigationViewController {
    // MARK: - Properties
    var viewModel: ShareWithFriendViewModelType!

    // MARK: - UI Elements
    private lazy var imageWind: UIImageView = {
        let imv = UIImageView(image: UIImage(named: ImagesAsset.windscribeHeart))
        imv.setDimensions(height: 86, width: 104)
        imv.contentMode = .scaleAspectFit
        return imv
    }()
    private lazy var headerTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = TextsAsset.Refer.shareWindscribeWithFriend
        lbl.font = .bold(size: 21)
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()

    lazy var referral1View: CheckView = {
        let vw = CheckView(content: TextsAsset.Refer.getAdditionalPerMonth, isDarkMode: viewModel.isDarkMode)
        vw.isHidden = false
        return vw
    }()

    lazy var referral2View: CheckView = {
        let vw = CheckView(content: TextsAsset.Refer.goProTo, isDarkMode: viewModel.isDarkMode)
        vw.isHidden = false
        return vw
    }()

    lazy var topView: UIStackView = {
        let vw = UIStackView(arrangedSubviews: [
            headerTitle,
            referral1View,
            referral2View
        ])
        vw.axis = .vertical
        vw.setCustomSpacing(38, after: headerTitle)
        vw.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 16))
        return vw
    }()

    private lazy var descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = TextsAsset.Refer.refereeMustProvideUsername

        lbl.font = .text(size: 12)
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var bottomView: UIStackView = {
        let vw = UIStackView(arrangedSubviews: [
            descriptionLabel
        ])
        vw.axis = .vertical
        vw.setCustomSpacing(38, after: headerTitle)
        vw.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 16))
        return vw
    }()

    lazy var shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.rx.tap.bind { [weak self] in
            let linkString = self?.viewModel.appStoreLink ?? ""
            let message = self?.viewModel.inviteMessage ?? ""
            self?.inviteAction(message: message,
                         link: linkString)
        }.disposed(by: disposeBag)

        btn.anchor(height: 48)
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        btn.setTitleColor(UIColor.midnight, for: .normal)
        btn.backgroundColor = UIColor.seaGreen
        btn.setTitle("Share Invite Link".localize(), for: .normal)
        return btn
    }()

    // MARK: - Config
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupLocalized()
        viewModel.referFriendManager.setShowedShareDialog(showed: true)
        bindViews()
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    override func setupLocalized() {
        super.setupLocalized()
        descriptionLabel.text = TextsAsset.Refer.refereeMustProvideUsername
        headerTitle.text = TextsAsset.Refer.shareWindscribeWithFriend
        shareButton.setTitle(TextsAsset.Refer.shareInviteLink, for: .normal)
        referral1View.updateContent(TextsAsset.Refer.getAdditionalPerMonth)
        referral2View.updateContent(TextsAsset.Refer.goProTo)
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe { isDarkMode in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupViews(isDark: isDarkMode)
                self.headerTitle.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                self.descriptionLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
                self.imageWind.updateTheme(isDark: isDarkMode)
            }
        }.disposed(by: disposeBag)
    }

    private func setup() {
        setupFillLayoutView()
        layoutView.stackView.addArrangedSubviews([
            imageWind,
            topView,
            shareButton,
            bottomView
        ])
        layoutView.stackView.spacing = 16
        let paddingTop = UIScreen.hasTopNotch ? 75.0 : 40.0
        layoutView.stackView.setPadding(UIEdgeInsets(top: paddingTop, left: 24, bottom: 16, right: 24))
        layoutView.stackView.setCustomSpacing(32, after: topView)
        layoutView.stackView.setCustomSpacing(36, after: shareButton)
    }

    private func inviteAction(message: String, link: String) {
        let objectsToShare = [message,link] as [Any]
        let activityViewController = UIActivityViewController(
            activityItems: objectsToShare,
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.sourceView = self.view
        present(activityViewController, animated: true)
    }
}
