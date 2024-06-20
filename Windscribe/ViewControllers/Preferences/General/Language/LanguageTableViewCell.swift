//
//	LanguageTableViewCell.swift
//	Windscribe
//
//	Created by Thomas on 25/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import RxSwift

class LanguageTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    lazy var nameLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.bold(size: 16)
        label.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.makeWidthAnchor(equalTo: 15)
        imageView.makeHeightAnchor(equalTo: 15)
        imageView.image = UIImage(named: ImagesAsset.greenCheckMark)
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        addSubviews()
        makeConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    private func addSubviews() {
        addSubview(nameLbl)
        addSubview(iconImageView)
    }

    private func makeConstraints() {
        nameLbl.makeTopAnchor(constant: 15)
        nameLbl.makeLeadingAnchor(constant: 15)
        nameLbl.makeBottomAnchor(constant: -15)
        iconImageView.makeCenterYAnchor()
        iconImageView.makeTrailingAnchor(constant: 15)
    }

    func bindView(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: { [weak self] in
            guard let self = self else { return }
            self.updateTheme(isDark: $0)
        }).disposed(by: disposeBag)
    }

    override func updateTheme(isDark: Bool) {
        iconImageView.updateTheme(isDark: isDark)
        nameLbl.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDark)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configData(_ data: LanguageDataCell) {
        nameLbl.text = data.language.name
        iconImageView.alpha = data.isShowGreenMarkCheck() ? 1 : 0
    }
}
