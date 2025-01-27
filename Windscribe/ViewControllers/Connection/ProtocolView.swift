//
//  ProtocolView.swift
//  Windscribe
//
//  Created by Thomas on 23/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

enum ProtocolViewType {
    case connected
    case normal
    case fail
    case nextUp
}

protocol ProtocolViewDelegate: AnyObject {
    func protocolViewDidSelect(_ protocolView: ProtocolView)
    func protocolViewNextUpCompleteCoundown(_ protocolView: ProtocolView)
}

class ProtocolView: UIView {
    private(set) var type: ProtocolViewType
    private(set) var protocolDescription: String = "One line description.".localize()
    weak var delegate: ProtocolViewDelegate?
    var protocolName: String
    var portName: String
    var fallbackType: ProtocolFallbacksType
    private let defaultCountdownTime = 10
    private(set) var countdownValue: Int = 10

    private var nextUpTimer: Timer?

    private let disposeBag = DisposeBag()

    // MARK: - UI Elements

    private lazy var wrapperView: UIView = {
        let vw = UIView()
        vw.layer.cornerRadius = 8
        return vw
    }()

    private var protocolLabel: UILabel = .init()

    private var portLabel: UILabel = .init()

    private lazy var protocolSeparateLine: UIView = {
        let vw = UIView()
        vw.anchor(width: 1)
        return vw
    }()

    private lazy var protocolStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            protocolLabel,
            protocolSeparateLine,
            portLabel,
            UIView(),
        ])
        stack.spacing = 8
        return stack
    }()

    private lazy var descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = protocolDescription
        lbl.alpha = 0.5
        lbl.font = UIFont.text(size: 16)
        lbl.textAlignment = .left
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var connectedLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Connected to".localize()
        lbl.font = .text(size: 12)
        lbl.textColor = .seaGreen
        return lbl
    }()

    private lazy var nextInLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Next Up In \(countdownValue)s".localize()
        lbl.font = .bold(size: 12)
        lbl.textColor = .seaGreen
        return lbl
    }()

    private lazy var topRightView: UIView = {
        let vw = UIView()
        let stack = UIStackView(arrangedSubviews: [
            connectedLabel,
            nextInLabel,
        ])
        vw.addSubview(stack)
        stack.fillSuperview()
        stack.axis = .vertical
        stack.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 4))
        vw.layer.cornerRadius = 6
        vw.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
        return vw
    }()

    private lazy var rightArrowImage: UIImageView = {
        let imv = UIImageView(image: UIImage(named: type == .connected ? ImagesAsset.greenCheckMark : ImagesAsset.rightArrow))
        imv.alpha = 0.5
        imv.anchor(height: 16)
        imv.contentMode = .scaleAspectFit
        return imv
    }()

    private lazy var failedLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Failed".localize()
        lbl.font = .text(size: 12)
        lbl.textColor = .failRed
        lbl.isHidden = true
        return lbl
    }()

    private lazy var mainstackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.setPadding(UIEdgeInsets(top: 14, left: 16, bottom: 15, right: 16))
        return stack
    }()

    // MARK: - Config

    init(type: ProtocolViewType, protocolName: String, portName: String, description: String, isDarkMode: BehaviorSubject<Bool>, delegate: ProtocolViewDelegate? = nil, fallbackType: ProtocolFallbacksType) {
        self.type = type
        self.delegate = delegate
        self.protocolName = protocolName
        self.portName = portName
        protocolDescription = description
        self.fallbackType = fallbackType
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var topRightViewTopConstraint: NSLayoutConstraint?
    var topRightViewTrailingConstraint: NSLayoutConstraint?
    var rightArrowImageCenterYConstraint: NSLayoutConstraint?
    var rightArrowImageCenterYDescConstraint: NSLayoutConstraint?

    private func setup() {
        addSubview(mainstackView)
        mainstackView.fillSuperview()
        mainstackView.addArrangedSubviews([
            protocolStack,
            descriptionLabel,
        ])
        mainstackView.addSubview(wrapperView)
        wrapperView.fillSuperview()
        protocolLabel.text = protocolName
        portLabel.text = portName

        addSubview(topRightView)
        addSubview(rightArrowImage)
        addSubview(failedLabel)

        setupConstraint()
        configUITopRightView()
        configUIRightArrow()

        let gs = UITapGestureRecognizer(target: self, action: #selector(selectedAction))
        addGestureRecognizer(gs)
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.updateUI(isDarkMode: $0)
            self.wrapperView.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: $0)
            self.protocolLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.portLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.protocolSeparateLine.backgroundColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.descriptionLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            if type != .connected { rightArrowImage.updateTheme(isDark: $0) }
        }).disposed(by: disposeBag)
    }

    @objc func selectedAction() {
        delegate?.protocolViewDidSelect(self)
    }

    private func setupConstraint() {
        topRightView.translatesAutoresizingMaskIntoConstraints = false
        topRightViewTopConstraint = NSLayoutConstraint(item: topRightView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 2)
        topRightViewTrailingConstraint = NSLayoutConstraint(item: topRightView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -2)
        topRightViewTopConstraint?.isActive = true
        topRightViewTrailingConstraint?.isActive = true

        rightArrowImage.anchor(right: rightAnchor, paddingRight: 16)
        rightArrowImageCenterYConstraint = NSLayoutConstraint(item: rightArrowImage, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        rightArrowImageCenterYDescConstraint = NSLayoutConstraint(item: rightArrowImage, attribute: .centerY, relatedBy: .equal, toItem: descriptionLabel, attribute: .centerY, multiplier: 1, constant: 0)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.trailingAnchor.constraint(equalTo: mainstackView.trailingAnchor, constant: -80).isActive = true
        failedLabel.anchor(right: rightAnchor, paddingRight: 20)
        failedLabel.centerYToSuperview()
    }

    private func updateUI(isDarkMode: Bool) {
        switch type {
        case .connected:
            wrapperView.backgroundColor = .clear
            wrapperView.layer.borderColor = UIColor.seaGreen(opacity: 0.1).cgColor
            wrapperView.layer.borderWidth = 2
        case .normal, .nextUp:
            wrapperView.backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)
        case .fail:
            wrapperView.backgroundColor = .clear
            wrapperView.layer.borderColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode).cgColor
            wrapperView.layer.borderWidth = 2
        }

        switch type {
        case .connected:
            protocolLabel.textColor = UIColor.seaGreen
            portLabel.textColor = UIColor.seaGreen(opacity: 0.5)
            descriptionLabel.textColor = UIColor.seaGreen(opacity: 0.5)
            protocolSeparateLine.backgroundColor = UIColor.seaGreen(opacity: 0.5)
            topRightView.backgroundColor = UIColor.seaGreen(opacity: 0.1)
        case .normal, .nextUp, .fail:
            protocolLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            portLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
            descriptionLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
        }
    }

    private func configUITopRightView() {
        switch type {
        case .connected:
            topRightView.isHidden = false
            connectedLabel.isHidden = false
            nextInLabel.isHidden = true
            topRightViewTopConstraint?.constant = 2
            topRightViewTrailingConstraint?.constant = -2
            topRightView.layer.cornerRadius = 6
            topRightView.backgroundColor = UIColor.seaGreen(opacity: 0.1)
        case .normal:
            topRightView.isHidden = true
        case .fail:
            topRightView.isHidden = true
        case .nextUp:
            connectedLabel.isHidden = true
            if fallbackType == .change {
                nextInLabel.isHidden = true
                topRightView.isHidden = true
            } else {
                nextInLabel.isHidden = false
                topRightView.isHidden = false
            }
            topRightViewTopConstraint?.constant = 0
            topRightViewTrailingConstraint?.constant = 0
            topRightView.layer.cornerRadius = 8
            topRightView.backgroundColor = UIColor.seaGreen(opacity: 0.1)
            runNextUpCountdown()
        }
    }

    private func runNextUpCountdown() {
        invalidateTimer()
        nextUpTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getTimeAndDisplay), userInfo: nil, repeats: true)
    }

    @objc private func getTimeAndDisplay() {
        DispatchQueue.main.async {
            self.countdownValue -= 1
            let displayTime = self.countdownValue
            if displayTime <= 0 {
                self.invalidateTimer()
                self.delegate?.protocolViewNextUpCompleteCoundown(self)
            } else {
                self.nextInLabel.text = "Next Up In \(displayTime)s"
            }
        }
    }

    func invalidateTimer() {
        nextUpTimer?.invalidate()
        countdownValue = defaultCountdownTime
    }

    private func configUIRightArrow() {
        switch type {
        case .connected:
            rightArrowImage.isHidden = false
            rightArrowImageCenterYConstraint?.isActive = false
            rightArrowImageCenterYDescConstraint?.isActive = true
            failedLabel.isHidden = true
        case .normal:
            rightArrowImage.isHidden = false
            rightArrowImageCenterYConstraint?.isActive = true
            rightArrowImageCenterYDescConstraint?.isActive = false
            failedLabel.isHidden = true
        case .fail:
            rightArrowImage.isHidden = true
            failedLabel.isHidden = false
        case .nextUp:
            rightArrowImage.isHidden = false
            rightArrowImageCenterYConstraint?.isActive = false
            rightArrowImageCenterYDescConstraint?.isActive = true
            failedLabel.isHidden = true
        }
    }
}
