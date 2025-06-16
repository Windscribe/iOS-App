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
    var shouldTintIcon: Bool { get }
    var iconAspect: UIView.ContentMode { get }
    var clipIcon: Bool { get }
    var actionImage: UIImage? { get }
    var iconSize: CGFloat { get }
    var actionSize: CGFloat { get }
    var actionRightOffset: CGFloat { get }
    var actionOpacity: Float { get }
    var serverHealth: CGFloat { get }
    var showServerHealth: Bool { get }
    func nameColor(for isDarkMode: Bool) -> UIColor
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
    var disposeBag = DisposeBag()
    var icon = UIImageView()
    var circleView = UIView()
    var actionImage = UIImageView()
    var nameLabel = UILabel()
    var nameInfoStackView = UIStackView()
    var healthCircle = HealthCircleView()
    var tableViewTag: Int = 0

    var viewModel: ServerCellModelType?

    private var isDarkMode: Bool = DefaultValues.darkMode

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        actionImage.image = UIImage(named: ImagesAsset.cellExpand)
        actionImage.contentMode = .scaleAspectFit

        nameLabel.font = UIFont.medium(size: 16)

        nameInfoStackView.addArrangedSubview(nameLabel)
        nameInfoStackView.spacing = 5

        circleView.backgroundColor = .clear
        circleView.layer.cornerRadius = 12
        circleView.layer.borderWidth = 1
        circleView.clipsToBounds = true

        contentView.addSubview(icon)
        contentView.addSubview(circleView)
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
        circleView.translatesAutoresizingMaskIntoConstraints = false
        actionImage.translatesAutoresizingMaskIntoConstraints = false
        nameInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        healthCircle.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // icon
            icon.topAnchor.constraint(equalTo: self.topAnchor, constant: 13),
            icon.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            icon.heightAnchor.constraint(equalToConstant: viewModel.iconSize),
            icon.widthAnchor.constraint(equalToConstant: viewModel.iconSize),

            // circleView
            circleView.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            circleView.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            circleView.heightAnchor.constraint(equalToConstant: 24),
            circleView.widthAnchor.constraint(equalToConstant: 24),

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
        if viewModel.shouldTintIcon {
            icon.setImageColor(color: .from(.locationColor, isDarkMode))
        }
        actionImage.image = viewModel.actionImage
        actionImage.setImageColor(color: .from(.iconColor, isDarkMode))

        nameLabel.textColor = viewModel.nameColor(for: isDarkMode)
        actionImage.layer.opacity = viewModel.actionOpacity

        healthCircle.health = viewModel.serverHealth

        circleView.isHidden = !viewModel.showServerHealth
        healthCircle.isHidden = !viewModel.showServerHealth
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDarkMode in
            self.actionImage.setImageColor(color: .from(.iconColor, isDarkMode))
            self.circleView.layer.borderColor = UIColor.from(.loadCircleColor, isDarkMode).cgColor
            self.isDarkMode = isDarkMode
        }).disposed(by: disposeBag)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressState(active: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressState(active: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setPressState(active: false)
    }

    func setPressState(active: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (active ? 0.0 : 0.3)) { [weak self] in
            guard let self = self else { return }
            self.updateUI()
            self.backgroundColor = active ? .from(.pressStateColor, self.isDarkMode): .clear
        }
    }
}
