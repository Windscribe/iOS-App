//
//  LookAndFeelViewController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxGesture
import RxSwift
import StoreKit
import UIKit

class LookAndFeelViewController: WSNavigationViewController {

    var viewModel: LookAndFeelViewModelType!
    var logger: FileLogger!

    // MARK: UI Elements

    // Appearance
    private lazy var appearanceRow: SelectableView = {
        let view = SelectableView(
            header: LookAndFeelHelper.getTitle(.appearance),
            currentOption: viewModel.getCurrentApperance(),
            listOption: TextsAsset.appearances,
            icon: LookAndFeelHelper.getAsset(.appearance),
            isDarkMode: viewModel.isDarkMode,
            subTitle: LookAndFeelHelper.getDescription(.appearance),
            delegate: self
        )
        view.hideShowExplainIcon()
        return view
    }()

    // Custom Background

    private lazy var backgroundEffectRow = CustomBackgroundEffectView(
        isDarkMode: viewModel.isDarkMode,
        aspectRatioInitialType: viewModel.getAspectRatio(),
        connectInitialType: viewModel.getBackgroundEffect(for: .connect),
        disconnectInitialType: viewModel.getBackgroundEffect(for: .disconnect)
    ).then {
        $0.delegate = self
    }

    // Custom Sounds

    private lazy var soundEffectRow = CustomSoundEffectView(
        isDarkMode: viewModel.isDarkMode,
        connectInitialType: viewModel.getSoundEffect(for: .connect),
        disconnectInitialType: viewModel.getSoundEffect(for: .disconnect)
    ).then {
        $0.delegate = self
    }

    // Location

    private lazy var renameLocationsRow: HelpView = {
        let row = HelpView(item: HelpItem(icon: ImagesAsset.Help.community,
                                          title: "Rename Locations",
                                          subTitle: "Change location names to your liking."),
                           type: .navigation,
                           actionableHeader: false,
                           delegate: nil,
                           isDarkMode: viewModel.isDarkMode)

        exportRow.do {
            $0.addTopDivider()
            $0.addBottomDivider()
        }

        importRow.do {
            $0.addBottomDivider()
        }

        row.do {
            $0.header.isUserInteractionEnabled = false
            $0.listSubView = [exportRow, importRow, resetRow]
        }

        return row
    }()

    private lazy var exportRow = HelpSubRowView(header: "Export",
                                                isDarkMode: viewModel.isDarkMode,
                                                delegate: self)

    private lazy var importRow = HelpSubRowView(header: "Import",
                                                 isDarkMode: viewModel.isDarkMode,
                                                 delegate: self)

    private lazy var resetRow = HelpSubRowView(header: "Reset",
                                               isDarkMode: viewModel.isDarkMode,
                                               delegate: self)

    // Version

    private lazy var versionRow = UIStackView(
        arrangedSubviews: [versionLabel, UIView(), currentVersionLabel]).then {
            $0.setPadding(UIEdgeInsets(inset: 16))
            $0.axis = .horizontal
            $0.spacing = 8
            $0.isUserInteractionEnabled = true
            $0.addSubview(versionBorderView)
            versionBorderView.fillSuperview()
            versionBorderView.sendToBack()
    }

    private lazy var versionLabel = UILabel().then {
        $0.font = UIFont.text(size: 16)
    }

    private lazy var currentVersionLabel = UILabel().then {
        $0.text = viewModel.getVersion()
        $0.font = UIFont.text(size: 16)
        $0.isUserInteractionEnabled = true
    }

    private lazy var versionBorderView = UIView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        bindViews()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.setupTheme(isDark: isDark)
        }).disposed(by: disposeBag)

        currentVersionLabel.rx.tapGesture { gesture, _ in
            gesture.numberOfTapsRequired = 3
        }
        .when(.recognized)
        .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }

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
        titleLabel.text = TextsAsset.LookFeel.title
        setupFillLayoutView()

        layoutView.stackView.do {
            $0.addArrangedSubviews([
                appearanceRow,
                backgroundEffectRow,
                soundEffectRow,
                renameLocationsRow,
                versionRow
            ])

            $0.setPadding(UIEdgeInsets(inset: 16))
            $0.spacing = 16
        }
    }

    private func setupTheme(isDark: Bool) {
        super.setupViews(isDark: isDark)
        versionBorderView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDark).cgColor
        versionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
        currentVersionLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
    }

    override func setupLocalized() {
        titleLabel.text = TextsAsset.LookFeel.title

        appearanceRow.updateStringData(
            title: LookAndFeelHelper.getTitle(.appearance),
            optionTitle: viewModel.getCurrentApperance(),
            listOption: TextsAsset.appearances,
            subTitle: LookAndFeelHelper.getDescription(.appearance))

        versionLabel.text = LookAndFeelHelper.getTitle(.version)
    }
}

// MARK: Extensions

extension LookAndFeelViewController: SelectableViewDelegate {
    func selectableViewSelect(_ sender: SelectableView, option: String) {
        switch sender {
        case appearanceRow:
            viewModel.didSelectedAppearance(value: option)
        default:
            break
        }
    }

    func selectableViewDirection(_ sender: SelectableView) {
        // No-op
    }
}

extension LookAndFeelViewController: CustomSoundEffectViewDelegate {
    func customSoundDidChangeType(_ domain: SoundAssetDomainType, type: SoundEffectType) {
        viewModel.updateSoundEffectType(domain: domain, type: type)
    }

    func customSoundDidPickCustomFile(domain: SoundAssetDomainType, path: String) {
        viewModel.saveCustomSoundPath(domain: domain, path: path)
    }
}

extension LookAndFeelViewController: CustomBackgroundEffectViewDelegate {
    func customBackgroundDidChangeAspectRatio(type: BackgroundAspectRatioType) {
        viewModel.updateAspectRatioType(type: type)
    }

    func customBackgroundDidChangeType(_ domain: BackgroundAssetDomainType, type: BackgroundEffectType) {
        viewModel.updateBackgroundEffectType(domain: domain, type: type)
    }
}

extension LookAndFeelViewController: HelpSubRowViewDelegate {
    func helpSubRowViewDidTap(_ sender: HelpSubRowView) {
        switch sender {
        case exportRow:
            print("Export Row activated")
        case importRow:
            print("Import Row activated")
        case resetRow:
            print("Reset Row activated")
        default:
            break
        }
    }
}
