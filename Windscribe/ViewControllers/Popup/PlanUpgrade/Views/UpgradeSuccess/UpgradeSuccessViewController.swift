//
//  UpgradeSuccessViewController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit

class UpgradeSuccessViewController: WSUIViewController {

    // MARK: UI components

    private let mainContentScrollView = UIScrollView()
    private let mainStackView = UIStackView()
    private let logoView = UpgradeSuccessLogoView()
    private var benefitsListView: UpgradeSuccessBenefitView?
    private let dividerView = UIView()
    private var shareOptionsView: UpgradeSuccessShareView?
    private let startButton = PlanUpgradeGradientButton()
    private var contentVerticalSpacing: CGFloat = 24
    private var contentHorizontalSpacing: CGFloat = 16

    private let viewModel = UpgradeSuccessViewModel()

    let successScreenDismissed = PublishSubject<Void>()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        createViews()
        setTheme()
        doLayout()

        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        changeNavigationBarStyle(isHidden: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateViewSpacing()
    }

    override var traitCollection: UITraitCollection {
        let maxCategory: UIContentSizeCategory = .extraExtraLarge

        if super.traitCollection.preferredContentSizeCategory > maxCategory {
            return UITraitCollection(traitsFrom: [
                super.traitCollection,
                UITraitCollection(preferredContentSizeCategory: maxCategory)
            ])
        }

        return super.traitCollection
    }

    // MARK: Set Theme

    private func createViews() {
        shareOptionsView = UpgradeSuccessShareView(shareOptions: viewModel.shareOptions)
        benefitsListView = UpgradeSuccessBenefitView(featureList: viewModel.featureTitles)
    }

    private func setTheme() {
        setThemeNavigationBar()
        setThemeBackground()
        setThemeMainContentView()
        setThemeDividerView()
        setThemeStartButton()
    }

    private func setThemeNavigationBar() {
        navigationController?.do {
            $0.navigationBar.isTranslucent = true
            $0.navigationBar.setBackgroundImage(UIImage(), for: .default)
            $0.navigationBar.shadowImage = UIImage()
        }
    }

    private func setThemeBackground() {
        view.backgroundColor = UIColor.planUpgradeBackground

        contentVerticalSpacing = isRegularSizeClass ? (isPortrait ? 64 : 28) : 24
        contentHorizontalSpacing = isRegularSizeClass ? 32 : 16
    }

    private func setThemeMainContentView() {
        mainStackView.do {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .fill
        }
    }

    private func setThemeDividerView() {
        dividerView.backgroundColor = .whiteWithOpacity(opacity: 0.10)
        dividerView.snp.makeConstraints {
            $0.height.equalTo(1)
        }
    }

    private func setThemeStartButton() {
        startButton.do {
            $0.setTitle(TextsAsset.UpgradeView.planBenefitSuccessStartTitle, for: .normal)
            $0.setTitleColor(.black, for: .normal)
            $0.titleLabel?.font = UIFont.bold(textStyle: .title3)
            $0.layer.cornerRadius = 24
            $0.layer.masksToBounds = true
        }
    }

    // MARK: Do Layout

    private func doLayout() {
        layoutNavigationBar()
        layoutMainContentView()
        layoutLogoView()
        layoutBenefitsSection()
        layoutDividerView()
        layoutShareOptionListView()
        layoutSubscribeButton()
    }

    private func layoutNavigationBar() {
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = UIColor.whiteWithOpacity(opacity: 0.8)

        closeButton.setTitleTextAttributes(
            [.font: UIFont.semiBold(textStyle: .title3)],
            for: .normal)
        navigationItem.leftBarButtonItem = closeButton
    }

    private func layoutMainContentView() {
        view.addSubview(mainContentScrollView)
        mainContentScrollView.addSubview(mainStackView)

        mainContentScrollView.snp.makeConstraints {
            $0.top.equalTo(view.snp.top)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
        }

        mainStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview() // Ensure horizontal scrolling is disabled
        }

        mainContentScrollView.alwaysBounceHorizontal = false
        mainContentScrollView.showsHorizontalScrollIndicator = false
    }

    private func layoutLogoView() {
        mainStackView.addArrangedSubview(logoView)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: logoView)

        logoView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutBenefitsSection() {
        guard let benefitsListView = benefitsListView else { return }

        mainStackView.addArrangedSubview(benefitsListView)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: benefitsListView)

        benefitsListView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutDividerView() {
        mainStackView.addArrangedSubview(dividerView)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: dividerView)

        dividerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutShareOptionListView() {
        guard let shareOptionsView = shareOptionsView else { return }

        mainStackView.addArrangedSubview(shareOptionsView)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: shareOptionsView)

        shareOptionsView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    private func layoutSubscribeButton() {
        mainStackView.addArrangedSubview(startButton)
        mainStackView.setCustomSpacing(contentVerticalSpacing, after: startButton)

        startButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
            $0.height.equalTo(50)
        }
    }

    private func updateViewSpacing() {
        guard isRegularSizeClass else { return }

        contentVerticalSpacing = isRegularSizeClass ? (isPortrait ? 64 : 28) : 24
        contentHorizontalSpacing = isRegularSizeClass ? 32 : 16

        guard let benefitsListView = benefitsListView, let shareOptionsView = shareOptionsView else { return }

        mainStackView.do {
            $0.setCustomSpacing(contentVerticalSpacing, after: logoView)
            $0.setCustomSpacing(contentVerticalSpacing, after: benefitsListView)
            $0.setCustomSpacing(contentVerticalSpacing, after: dividerView)
            $0.setCustomSpacing(contentVerticalSpacing, after: shareOptionsView)
            $0.setCustomSpacing(contentVerticalSpacing, after: startButton)
        }

        logoView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        benefitsListView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        dividerView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        shareOptionsView.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }

        startButton.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(contentHorizontalSpacing)
        }
    }

    // MARK: Actions & Action Bindings

    @objc func closeButtonTapped() {
        successScreenDismissed.onNext(())
    }

    private func setupBindings() {
        shareOptionsView?.didSelectOption
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] url in
                self?.openLink(url: url)
            })
            .disposed(by: disposeBag)

        startButton.rx.tap
            .bind { [weak self] in
                self?.successScreenDismissed.onNext(())
            }
            .disposed(by: disposeBag)
    }
}
