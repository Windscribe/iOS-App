//
//    GeneralViewController.swift
//    Windscribe
//
//    Created by Thomas on 17/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxGesture
import RxSwift
import StoreKit
import UIKit

class GeneralViewController: WSNavigationViewController {
    // MARK: - State properties

    var viewModel: GeneralViewModelType!, router: GeneralRouter!, popupRouter: PopupRouter!, logger: FileLogger!

    // MARK: - UI Elements

    private lazy var locationOrderRow: SelectableView = {
        let view = SelectableView(
            header: GeneralHelper.getTitle(.locationOrder),
            currentOption: viewModel.getCurrentLocationOrder(),
            listOption: TextsAsset.orderPreferences,
            icon: GeneralHelper.getAsset(.locationOrder),
            isDarkMode: viewModel.isDarkMode,
            subTitle: GeneralHelper.getDescription(.locationOrder),
            delegate: self
        )
        view.hideShowExplainIcon()
        return view
    }()

    private lazy var languageRow: SelectableView = {
        let view = SelectableView(
            type: .direction,
            header: GeneralHelper.getTitle(.language),
            currentOption: viewModel.getCurrentLanguage(),
            listOption: TextsAsset.General.languages,
            icon: GeneralHelper.getAsset(.language),
            isDarkMode: viewModel.isDarkMode,
            subTitle: GeneralHelper.getDescription(.language),
            delegate: self
        )
        view.hideShowExplainIcon()
        return view
    }()

    private lazy var notificationRow: SelectableView = {
        let view = SelectableView(
            type: .directionWithoutIcon,
            header: GeneralHelper.getTitle(.notification),
            currentOption: TextsAsset.General.openSettings,
            listOption: [],
            icon: GeneralHelper.getAsset(.notification),
            isDarkMode: viewModel.isDarkMode,
            subTitle: GeneralHelper.getDescription(.notification),
            delegate: self
        )
        view.hideShowExplainIcon()
        return view
    }()

    private lazy var hapticFeedbackRow = makeRatioView(type: .hapticFeeback)

    private lazy var versionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = TextsAsset.General.version
        lbl.font = UIFont.text(size: 16)
        return lbl
    }()

    private lazy var currentVersionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = viewModel.getVersion()
        lbl.font = UIFont.text(size: 16)
        lbl.isUserInteractionEnabled = true
        return lbl
    }()

    private lazy var versionRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            versionLabel, UIView(), currentVersionLabel
        ])
        stack.setPadding(UIEdgeInsets(inset: 16))
        stack.axis = .horizontal
        stack.spacing = 8
        stack.isUserInteractionEnabled = true
        stack.addSubview(versionBorderView)
        versionBorderView.fillSuperview()
        versionBorderView.sendToBack()
        return stack
    }()

    private lazy var versionBorderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViews()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupTheme(isDark: isDark)
        }).disposed(by: disposeBag)
        currentVersionLabel.rx.anyGesture(.longPress()).skip(1).subscribe(onNext: { _ in
            self.popupRouter.routeTo(to: RouteID.shakeForDataPopUp, from: self)
        }).disposed(by: disposeBag)

        currentVersionLabel.rx.tapGesture { gesture, _ in
            gesture.numberOfTapsRequired = 3
        }
        .when(.recognized)
        .subscribe(onNext: { _ in
            self.logger.logD(self, "Tried showing rate dialog manually")
            let scenes = UIApplication.shared.connectedScenes

            if let windowScene = scenes.first as? UIWindowScene {
                self.logger.logD(self, "Attempting show rate popup.")
                SKStoreReviewController.requestReview(in: windowScene)
            }
        })
        .disposed(by: disposeBag)
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    private func setupViews() {
        titleLabel.text = TextsAsset.General.title
        setupFillLayoutView()
        if UIDevice.current.userInterfaceIdiom == .pad {
            layoutView.stackView.addArrangedSubviews([
                locationOrderRow,
                languageRow,
                notificationRow,
                versionRow
            ])
        } else {
            layoutView.stackView.addArrangedSubviews([
                locationOrderRow,
                languageRow,
                notificationRow,
                versionRow
            ])
        }

        layoutView.stackView.setPadding(UIEdgeInsets(inset: 16))
        layoutView.stackView.spacing = 16
    }

    private func makeRatioView(type: ConnectionSecure) -> ConnectionSecureView {
        let view = ConnectionSecureView(isDarkMode: viewModel.isDarkMode)
        view.titleLabel.text = type.title
        view.subTitleLabel.text = type.description
        view.hideShowExplainIcon(true)
        switch type {
        case .hapticFeeback:
            view.switchButton.setStatus(viewModel.getHapticFeedback())
            view.setImage(UIImage(named: GeneralHelper.getAsset(.hapticFeedback)))
            view.subTitleLabel.text = GeneralHelper.getDescription(.hapticFeedback)
            view.connectionSecureViewSwitchAcction = { [weak self] in
                self?.viewModel.updateHapticFeedback()
            }
        default:
            break
        }
        return view
    }

    // MARK: - Actions

    @objc func pushNotificationSettingsButtonTapped() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .denied:
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                }
            case .notDetermined:
                self.viewModel.askForPushNotificationPermission()
            default:
                break
            }
        }
    }

    private func setupTheme(isDark: Bool) {
        super.setupViews(isDark: isDark)
        versionBorderView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
        versionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
        currentVersionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
    }

    override func setupLocalized() {
        titleLabel.text = TextsAsset.General.title
        locationOrderRow.updateStringData(title: GeneralHelper.getTitle(.locationOrder), optionTitle: viewModel.getCurrentLocationOrder(), listOption: TextsAsset.orderPreferences, subTitle: GeneralHelper.getDescription(.locationOrder))
        languageRow.updateStringData(title: GeneralHelper.getTitle(.language), optionTitle: viewModel.getCurrentLanguage(), listOption: TextsAsset.General.languages, subTitle: GeneralHelper.getDescription(.language))
        notificationRow.updateStringData(title: GeneralHelper.getTitle(.notification), optionTitle: TextsAsset.General.openSettings, listOption: [], subTitle: GeneralHelper.getDescription(.notification))
        versionLabel.text = TextsAsset.General.version
        hapticFeedbackRow.updateStringData(title: GeneralHelper.getTitle(.hapticFeedback), subTitle: GeneralHelper.getDescription(.hapticFeedback))
    }
}

// MARK: Extensions

extension GeneralViewController: SelectableViewDelegate {
    func selectableViewSelect(_ sender: SelectableView, option: String) {
        switch sender {
        case locationOrderRow:
            viewModel.didSelectedLocationOrder(value: option)
        default:
            break
        }
    }

    func selectableViewDirection(_ sender: SelectableView) {
        switch sender {
        case languageRow:
            router.routeTo(to: RouteID.language, from: self)
        case notificationRow:
            pushNotificationSettingsButtonTapped()
        default:
            break
        }
    }
}
