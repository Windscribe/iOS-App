//
//  UpgradeSuccessBenefitView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class UpgradeSuccessBenefitView: UIView {

    private let listStackView = UIStackView()
    private let disposeBag = DisposeBag()

    init(featureList: BehaviorSubject<[String]>) {
        super.init(frame: .zero)

        setupUI()
        bindFeatureList(featureList)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        listStackView.do {
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 20 : 10) : 8
            $0.alignment = .fill
            $0.distribution = .fill
        }

        addSubview(listStackView)

        listStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindFeatureList(_ features: BehaviorSubject<[String]>) {
        features
            .observe(on: MainScheduler.instance)
            .bind { [weak self] featureList in
                self?.updateFeatureList(featureList)
            }
            .disposed(by: disposeBag)
    }

    private func updateFeatureList(_ featureTitles: [String]) {
        listStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        featureTitles.forEach { title in
            let featureRow = createFeatureRow(title: title)
            listStackView.addArrangedSubview(featureRow)
        }
    }

    private func createFeatureRow(title: String) -> UIView {
        let rowStackView = UIStackView()
        let titleLabel = UILabel()
        let iconImageView = UIImageView()

        rowStackView.do {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.alignment = .center
            $0.distribution = .fill
        }

        titleLabel.do {
            $0.text = title
            $0.font = UIFont.medium(textStyle: .subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .white
        }

        iconImageView.do {
            $0.image = UIImage(named: ImagesAsset.Subscriptions.checkTerms)
            $0.contentMode = .scaleAspectFit
        }

        rowStackView.addArrangedSubviews([titleLabel, iconImageView])

        iconImageView.snp.makeConstraints {
            $0.width.height.equalTo(25)
        }

        iconImageView.do {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        return rowStackView
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 20 : 10) : 8
        listStackView.spacing = newSpacing
    }
}
