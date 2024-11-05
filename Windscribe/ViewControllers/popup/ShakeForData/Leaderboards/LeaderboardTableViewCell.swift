//
//  LeaderboardTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-13.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class LeaderboardTableViewCell: UITableViewCell {
    var nameLabel = UILabel()
    var scoreLabel = UILabel()
    var cellDivider = UIView()
    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear

        nameLabel.font = UIFont.bold(size: 16)
        nameLabel.textAlignment = .left
        addSubview(nameLabel)

        scoreLabel.layer.opacity = 0.5
        scoreLabel.font = UIFont.text(size: 16)
        scoreLabel.textAlignment = .left
        addSubview(scoreLabel)

        cellDivider.layer.opacity = 0.10
        addSubview(cellDivider)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // nameLabel
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nameLabel.heightAnchor.constraint(equalToConstant: 16),

            // scoreLabel
            scoreLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scoreLabel.heightAnchor.constraint(equalToConstant: 20),

            // cellDivider
            cellDivider.bottomAnchor.constraint(equalTo: bottomAnchor),
            cellDivider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            cellDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            cellDivider.heightAnchor.constraint(equalToConstant: 2),
        ])
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDark in
            self.nameLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.scoreLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.cellDivider.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
        }).disposed(by: disposeBag)
    }

    func setScore(with displayingScore: Score) {
        nameLabel.text = displayingScore.user
        scoreLabel.text = "\(displayingScore.score)"
        if displayingScore.you {
            nameLabel.textColor = UIColor.seaGreen
            scoreLabel.textColor = UIColor.seaGreen
        }
    }
}
