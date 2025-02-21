//
//  UpgradeSuccessShareView.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

class UpgradeSuccessShareView: UIView {

    // MARK: UI Components

    private let stackView = UIStackView()
    private let shareTitleLabel = UILabel()

    private var shareOptions: BehaviorSubject<[ShareOption]>
    let didSelectOption = PublishSubject<URL>()
    private let disposeBag = DisposeBag()

    init(shareOptions: BehaviorSubject<[ShareOption]>) {
        self.shareOptions = shareOptions
        super.init(frame: .zero)

        setupUI()
        bindData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.do {
            $0.axis = .vertical
            $0.spacing = isRegularSizeClass ? (isPortrait ? 32 : 16) : 14
            $0.alignment = .fill
            $0.distribution = .fill
        }

        shareTitleLabel.do {
            $0.text = TextsAsset.UpgradeView.planBenefitSuccessShareTitle.uppercased()
            $0.font = UIFont.bold(textStyle: .footnote)
            $0.textColor = .white
            $0.textAlignment = .left
        }

        stackView.addArrangedSubview(shareTitleLabel)
    }

    private func bindData() {
        shareOptions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] options in
                guard let self else { return }
                self.stackView.arrangedSubviews
                    .filter { $0 !== self.shareTitleLabel }
                    .forEach { $0.removeFromSuperview() }

                options.forEach { self.addShareOption($0) }
            })
            .disposed(by: disposeBag)
    }

    private func addShareOption(_ option: ShareOption) {
        let rowStackView = UIStackView()
        let iconImageView = UIImageView()
        let titleLabel = UILabel()
        let chevronImageView = UIImageView()

        rowStackView.do {
            $0.axis = .horizontal
            $0.spacing = 12
            $0.alignment = .center
            $0.distribution = .fill
        }

        iconImageView.do {
            $0.image = UIImage(named: option.iconName)
            $0.contentMode = .scaleAspectFit
            $0.tintColor = .white
        }

        titleLabel.do {
            $0.text = option.title
            $0.font = UIFont.regular(textStyle: .subheadline)
            $0.textColor = .white
        }

        chevronImageView.do {
            $0.image = UIImage(systemName: "chevron.right")
            $0.contentMode = .scaleAspectFit
            $0.tintColor = .lightGray
        }

        rowStackView.addArrangedSubviews([iconImageView, titleLabel, chevronImageView])
        stackView.addArrangedSubview(rowStackView)

        iconImageView.snp.makeConstraints {
            $0.width.height.equalTo(25)
        }

        chevronImageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }

        rowStackView.isUserInteractionEnabled = true

        rowStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newSpacing: CGFloat = isRegularSizeClass ? (isPortrait ? 32 : 16) : 14
        stackView.spacing = newSpacing
    }

    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view as? UIStackView,
              let index = stackView.arrangedSubviews.firstIndex(of: row),
              let options = try? shareOptions.value() else { return }

        let selectedOption = options[index - 1]

        if let url = selectedOption.url {
            didSelectOption.onNext(url)
        }
    }
}
