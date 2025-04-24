//
//  ServerListCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 13/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import SwipeCellKit
import UIKit

protocol ServerCellModelType {
    var name: String { get }
    var iconImage: UIImage? { get }
    var iconAspect: UIView.ContentMode { get }
    var clipIcon: Bool { get }
    var actionImage: UIImage? { get }
    var iconSize: CGFloat { get }
    var actionSize: CGFloat { get }
    var actionRightOffset: CGFloat { get }
    var actionOpacity: Float { get }
    var nameOpacity: Float { get }
    var serverHealth: CGFloat { get }
}

class HealthCircleView: CompletionCircleView {
    var health: CGFloat? {
        didSet {
            self.percentage = health
        }
    }

    override func getColorFromPercentage() -> UIColor {
        guard let health = health else { return .red }
        if health < 0 {
            return .clear
        } else if health < 60 {
            return .green
        } else if health < 89 {
            return .yellow
        } else {
            return .red
        }
    }
}

class ServerListCell: SwipeTableViewCell {
    var icon = UIImageView()
    var locationLoadImage = UIImageView()
    var actionImage = UIImageView()
    var nameLabel = UILabel()
    var nameInfoStackView = UIStackView()
    var healthCircle = HealthCircleView()
    var tableViewTag: Int = 0

    var viewModel: ServerCellModelType?

    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.white

        locationLoadImage.image = UIImage(named: ImagesAsset.locationLoad)
        actionImage.image = UIImage(named: ImagesAsset.cellExpand)
        actionImage.contentMode = .scaleAspectFit

        nameLabel.font = UIFont.bold(size: 14)
        nameLabel.textColor = UIColor.nightBlue

        nameInfoStackView.addArrangedSubview(nameLabel)
        nameInfoStackView.spacing = 5

        contentView.addSubview(icon)
        contentView.addSubview(locationLoadImage)
        contentView.addSubview(healthCircle)
        contentView.addSubview(actionImage)
        contentView.addSubview(nameInfoStackView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    func updateLayout() {
        guard let viewModel = viewModel else { return }
        icon.clipsToBounds = viewModel.clipIcon
        icon.layer.cornerRadius = viewModel.iconSize / 2.0
        icon.contentMode = viewModel.iconAspect

        icon.translatesAutoresizingMaskIntoConstraints = false
        locationLoadImage.translatesAutoresizingMaskIntoConstraints = false
        actionImage.translatesAutoresizingMaskIntoConstraints = false
        nameInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        healthCircle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // icon
            icon.topAnchor.constraint(equalTo: self.topAnchor, constant: 13),
            icon.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            icon.heightAnchor.constraint(equalToConstant: viewModel.iconSize),
            icon.widthAnchor.constraint(equalToConstant: viewModel.iconSize),

            // locationLoadImage
            locationLoadImage.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            locationLoadImage.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            locationLoadImage.heightAnchor.constraint(equalToConstant: 24),
            locationLoadImage.widthAnchor.constraint(equalToConstant: 24),

            // healthCircle
            healthCircle.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            healthCircle.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            healthCircle.heightAnchor.constraint(equalTo: locationLoadImage.heightAnchor),
            healthCircle.widthAnchor.constraint(equalTo: locationLoadImage.widthAnchor),

            // nameInfoStackView
            nameInfoStackView.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            nameInfoStackView.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 16),

            // actionImage
            actionImage.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            actionImage.rightAnchor.constraint(equalTo: self.rightAnchor, constant: (viewModel.actionSize/2.0 - viewModel.actionRightOffset)),
            actionImage.heightAnchor.constraint(equalToConstant: viewModel.actionSize),
            actionImage.widthAnchor.constraint(equalToConstant: viewModel.actionSize)
        ])
    }

    func updateUI() {
        guard let viewModel = viewModel else { return }
        nameLabel.text = viewModel.name
        icon.image = viewModel.iconImage
        actionImage.image = viewModel.actionImage

        nameLabel.layer.opacity = viewModel.nameOpacity
        actionImage.layer.opacity = viewModel.actionOpacity

        healthCircle.health = viewModel.serverHealth
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDark in
            self.backgroundColor = isDark ? .nightBlue : .white
            self.nameLabel.textColor = isDark ? .white : .nightBlue
            self.actionImage.setImageColor(color: isDark ? .white : .nightBlue)
        }).disposed(by: disposeBag)
    }
}
