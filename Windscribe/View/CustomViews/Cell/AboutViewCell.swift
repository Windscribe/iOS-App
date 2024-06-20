//
//  AboutViewCell.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-07-28.
//  Copyright © 2021 Windscribe. All rights reserved.
//
import UIKit
import RxSwift

class AboutViewCell: WSTouchTableViewCell {
    lazy var titleLabel = UILabel()
    lazy var cellDivider = UIView()
    lazy var arrowIcon = UIImageView()
    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clear

        titleLabel.textColor = UIColor.white
        titleLabel.layer.opacity = 0.5
        titleLabel.font = UIFont.bold(size: 16)
        titleLabel.textAlignment = .left
        addSubview(titleLabel)

        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.image = UIImage(named: ImagesAsset.rightArrow)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        arrowIcon.layer.opacity = 0.25
        addSubview(arrowIcon)

        cellDivider.backgroundColor = UIColor.white
        cellDivider.layer.opacity = 0.05
        addSubview(cellDivider)
    }

    override func configNormal() {
        titleLabel.layer.opacity = 0.5
        arrowIcon.layer.opacity = 0.25
    }
    override func configHighlight() {
        titleLabel.layer.opacity = 1
        arrowIcon.layer.opacity = 1
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        let titleLabelContraints = [
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: 16),
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor,
                                             constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ]

        let arrowIconConstraints = [
            arrowIcon.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor,
                                               constant: 0),
            arrowIcon.rightAnchor.constraint(equalTo: rightAnchor,
                                             constant: -12),
            arrowIcon.widthAnchor.constraint(equalToConstant: 16),
            arrowIcon.heightAnchor.constraint(equalToConstant: 16)
        ]

        let cellDividerContraints = [
            cellDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                              constant: 16),
            cellDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellDivider.heightAnchor.constraint(equalToConstant: 2),
            cellDivider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(titleLabelContraints)
        NSLayoutConstraint.activate(arrowIconConstraints)
        NSLayoutConstraint.activate(cellDividerContraints)
    }

    var aboutItem: AboutItemCell? {
        didSet {
            updateUI()
        }
    }

    func updateUI() {
        guard let aboutItem = aboutItem else {
            return
        }
        titleLabel.text = aboutItem.title
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe( onNext: { isDarkMode in
            if !isDarkMode {
                self.cellDivider.backgroundColor = UIColor.midnight
                self.titleLabel.textColor = UIColor.midnight
                self.arrowIcon.image = UIImage(named: ImagesAsset.externalLink)
            } else {
                self.cellDivider.backgroundColor = UIColor.white
                self.titleLabel.textColor = UIColor.white
                self.arrowIcon.image = UIImage(named: ImagesAsset.DarkMode.externalLink)
            }
        }).disposed(by: disposeBag)
    }
}
