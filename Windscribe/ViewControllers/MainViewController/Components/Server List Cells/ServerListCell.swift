//
//  ServerListCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 13/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwipeCellKit
import UIKit

protocol ServerCellModelType {
    var name: String { get }
    var iconImage: UIImage? { get }
    var shouldTintIcon: Bool { get }
    var iconAspect: UIView.ContentMode { get }
    var actionImage: UIImage? { get }
    var actionVisible: Bool { get }
    var iconSize: CGFloat { get }
    var actionSize: CGFloat { get }
    var actionRightOffset: CGFloat { get }
    var actionOpacity: Float { get }
    var serverHealth: CGFloat { get }
    var locationLoad: Bool { get }
    var hasProLocked: Bool { get }
    var isDarkMode: Bool { get }
    func nameColor(for isDarkMode: Bool) -> UIColor
}

class HealthCircleView: CompletionCircleView {
    override init(lineWidth: CGFloat = 1, radius: CGFloat = 13) {
        super.init(lineWidth: lineWidth, radius: radius)
        startAngle = .pi / 2
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var health: CGFloat? {
        didSet {
            self.percentage = max(health ?? 0, 12.5)
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
    var circleView = UIView()
    var actionImage = UIImageView()
    var nameLabel = UILabel()
    var nameInfoStackView = UIStackView()
    var healthCircle = HealthCircleView()
    var iconsStackView = UIStackView()
    var proIcon = UIImageView()
    var tableViewTag: Int = 0

    private lazy var iconHeightConstraint: NSLayoutConstraint = {
        return icon.heightAnchor.constraint(equalToConstant: viewModel?.iconSize ?? 0)
    }()

    private lazy var iconWidthConstraint: NSLayoutConstraint = {
        return icon.widthAnchor.constraint(equalToConstant: viewModel?.iconSize ?? 0)
    }()

    var viewModel: ServerCellModelType?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        actionImage.image = UIImage(named: ImagesAsset.cellExpand)
        actionImage.contentMode = .scaleAspectFit

        nameLabel.font = UIFont.medium(size: 16)

        nameInfoStackView.addArrangedSubview(nameLabel)
        nameInfoStackView.axis = .horizontal
        nameInfoStackView.spacing = 5

        circleView.backgroundColor = .clear
        circleView.layer.cornerRadius = 13
        circleView.layer.borderWidth = 1
        circleView.clipsToBounds = true

        iconsStackView.axis = .horizontal
        iconsStackView.spacing = 16
        iconsStackView.addArrangedSubview(actionImage)

        proIcon.image = UIImage(named: ImagesAsset.proMiniImage)
        proIcon.setImageColor(color: .proStarColor)

        contentView.addSubview(icon)
        contentView.addSubview(circleView)
        contentView.addSubview(healthCircle)
        contentView.addSubview(iconsStackView)
        contentView.addSubview(nameInfoStackView)
        contentView.addSubview(proIcon)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func refreshUI() {
        updateLayout()
        updateUI()
    }

    func updateLayout() {
        guard let viewModel = viewModel else { return }
        icon.contentMode = viewModel.iconAspect

        icon.translatesAutoresizingMaskIntoConstraints = false
        circleView.translatesAutoresizingMaskIntoConstraints = false
        actionImage.translatesAutoresizingMaskIntoConstraints = false
        nameInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        healthCircle.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        iconsStackView.translatesAutoresizingMaskIntoConstraints = false
        proIcon.translatesAutoresizingMaskIntoConstraints = false

        iconHeightConstraint.constant = viewModel.iconSize
        iconWidthConstraint.constant = viewModel.iconSize

        NSLayoutConstraint.activate([
            // icon
            icon.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: self.leftAnchor, constant: 28),
            iconHeightConstraint,
            iconWidthConstraint,

            // circleView
            circleView.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            circleView.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            circleView.heightAnchor.constraint(equalToConstant: 26),
            circleView.widthAnchor.constraint(equalToConstant: 26),

            // healthCircle
            healthCircle.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            healthCircle.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            healthCircle.heightAnchor.constraint(equalTo: circleView.heightAnchor),
            healthCircle.widthAnchor.constraint(equalTo: circleView.widthAnchor),

            // nameLabel
            nameLabel.heightAnchor.constraint(equalToConstant: 20),

            // nameInfoStackView
            nameInfoStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameInfoStackView.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 16),

            // iconsStackView
            iconsStackView.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            iconsStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -viewModel.actionRightOffset),

            // actionImage
            actionImage.heightAnchor.constraint(equalToConstant: viewModel.actionSize),
            actionImage.widthAnchor.constraint(equalToConstant: viewModel.actionSize),

            // proIcon
            proIcon.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            proIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 11),
            proIcon.heightAnchor.constraint(equalToConstant: 16),
            proIcon.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    func updateUI() {
        guard let viewModel = viewModel else { return }
        nameLabel.text = viewModel.name
        icon.image = viewModel.iconImage
        if viewModel.shouldTintIcon {
            icon.setImageColor(color: .from(.locationColor, viewModel.isDarkMode))
        }
        actionImage.image = viewModel.actionImage
        actionImage.layer.opacity = viewModel.actionOpacity
        actionImage.setImageColor(color: .from(.iconColor, viewModel.isDarkMode))
        actionImage.isHidden = !viewModel.actionVisible

        nameLabel.textColor = viewModel.nameColor(for: viewModel.isDarkMode)

        healthCircle.health = viewModel.serverHealth

        circleView.isHidden = !viewModel.locationLoad
        healthCircle.isHidden = !viewModel.locationLoad

        proIcon.isHidden = !viewModel.hasProLocked

        iconHeightConstraint.constant = viewModel.iconSize
        iconWidthConstraint.constant = viewModel.iconSize

        actionImage.setImageColor(color: .from(.iconColor, viewModel.isDarkMode))
        circleView.layer.borderColor = UIColor.from(.loadCircleColor, viewModel.isDarkMode).cgColor

        let proImageName = viewModel.isDarkMode ? ImagesAsset.proMiniImage : ImagesAsset.proMiniLightImage
        proIcon.image = UIImage(named: proImageName)

        layoutIfNeeded()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.backgroundColor = .from(.pressStateColor, self.viewModel?.isDarkMode ?? false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        updateInactiveState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        updateInactiveState()
    }

    private func updateInactiveState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.backgroundColor = .clear
        }
    }
}
