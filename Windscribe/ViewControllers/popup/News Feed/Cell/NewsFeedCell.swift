//
//  NewsFeedCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class NewsFeedCell: UITableViewCell {

    private lazy var wrapperView = UIView()
    private lazy var titleLabel =  UILabel()
    private lazy var iconView = UIImageView()
    private lazy var readStatusDot = UIView()

    private lazy var backgroundShowView = UIView()

    private lazy var bodyStackView = UIStackView()
    private lazy var mainStackView = UIStackView()
    private lazy var textStackView = UIStackView()

    private lazy var textView = LinkTextView()
    private lazy var actionView = UIView()
    private lazy var actionLabel = UILabel()
    private lazy var actionIconView = UIImageView()

    var cellViewModel: NewsFeedCellViewModel?

    var didTapActionLabel: ((String, String?) -> Void)?
    var diTapHeader: (() -> Void)?

    func setViewModel(cellViewModel: NewsFeedCellViewModel?, width: CGFloat) {
        self.cellViewModel = cellViewModel
        updateUI(width: width)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .none

        contentView.isUserInteractionEnabled = false
        backgroundColor = UIColor.clear
        backgroundShowView.clipsToBounds = true
        backgroundShowView.backgroundColor = UIColor.white
        backgroundShowView.layer.opacity = 0.05

        // MARK: - Header
        titleLabel.font = UIFont.bold(size: 12)
        iconView.image = UIImage(named: ImagesAsset.whiteExpand)
        readStatusDot = UIView()
        readStatusDot.backgroundColor = UIColor.seaGreen
        readStatusDot.layer.cornerRadius = 3.5

        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(iconView)
        wrapperView.addSubview(readStatusDot)
        wrapperView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerDidTap)))

        // MARK: - Body
        bodyStackView.axis = .vertical
        bodyStackView.addArrangedSubview(textStackView)
        bodyStackView.addArrangedSubview(actionView)

        mainStackView.axis = .vertical
        mainStackView.addArrangedSubview(wrapperView)
        mainStackView.addArrangedSubview(bodyStackView)
        mainStackView.clipsToBounds = true

        configureTextStackView()
        configureActionButtonView()

        addSubview(backgroundShowView)
        addSubview(mainStackView)
    }

    private func configureTextStackView() {
        textView.font = UIFont.bold(size: 14)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.red
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        textStackView.axis = .horizontal
        textStackView.addArrangedSubview(textView)
    }

    private func configureActionButtonView() {
        actionLabel.font = UIFont.bold(size: 14)
        actionLabel.textColor = UIColor.white
        actionLabel.layer.opacity = 0.5
        actionLabel.isUserInteractionEnabled = true
        actionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionLabelDidTap)))

        actionIconView.image = UIImage(named: ImagesAsset.rightArrowBold)

        actionView.addSubview(actionLabel)
        actionView.addSubview(actionIconView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // MARK: - Header
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor, constant: 0),
            titleLabel.leftAnchor.constraint(equalTo: wrapperView.leftAnchor, constant: 16),
            titleLabel.rightAnchor.constraint(equalTo: iconView.leftAnchor, constant: -16)
        ])

        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapperView.heightAnchor.constraint(equalToConstant: 48)
        ])

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor),
            iconView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])

        readStatusDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            readStatusDot.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor),
            readStatusDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16 - readStatusDot.frame.width / 2),
            readStatusDot.widthAnchor.constraint(equalToConstant: 8),
            readStatusDot.heightAnchor.constraint(equalToConstant: 8)
        ])

        // MARK: - Body
        mainStackView.fitToSuperView(top: 0, leading: 12, bottom: 0, trailing: 16)
        backgroundShowView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 6)

        backgroundShowView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundShowView.topAnchor.constraint(equalTo: mainStackView.topAnchor),
            backgroundShowView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 4),
            backgroundShowView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            backgroundShowView.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor)
        ])

        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionLabel.topAnchor.constraint(equalTo: actionView.topAnchor),
            actionLabel.leadingAnchor.constraint(equalTo: actionView.leadingAnchor, constant: 16),
            actionLabel.bottomAnchor.constraint(equalTo: actionView.bottomAnchor, constant: -10),
            actionLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        actionIconView.translatesAutoresizingMaskIntoConstraints = false
        actionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionIconView.leftAnchor.constraint(equalTo: actionLabel.rightAnchor),
            actionIconView.centerYAnchor.constraint(equalTo: actionLabel.centerYAnchor),
            actionIconView.widthAnchor.constraint(equalToConstant: 16),
            actionIconView.heightAnchor.constraint(equalToConstant: 16),
            actionView.heightAnchor.constraint(equalToConstant: 30)
        ])

        self.textStackView.layoutIfNeeded()
        self.actionView.layoutIfNeeded()

    }

    func updateUI(width: CGFloat) {
        guard let cellViewModel = cellViewModel else {
            return
        }

        if let title = cellViewModel.title {
            titleLabel.text = title.uppercased()
            titleLabel.setLetterSpacing(value: 3.0)
        }

        if cellViewModel.isRead {
            readStatusDot.isHidden = true
        } else {
            readStatusDot.isHidden = false
        }

        if var message = cellViewModel.message {
            if checkHideLinkIfNeed() {
                message = removeRefLink(in: message)
            }
            if let messageData = message.data(using: .utf8) {
                textView.translatesAutoresizingMaskIntoConstraints = true
                textView.isScrollEnabled = false
                textView.htmlText(htmlData: messageData,
                                  font: .text(size: 14),
                                  foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5))
                var frame = self.textView.frame
                frame.size.width = width - 20
                textView.frame = frame
                textView.sizeToFit()
            }
        }

        actionView.isHidden = cellViewModel.action == nil
        actionLabel.text = cellViewModel.action?.label

        updateCollapseUI(collapsed: cellViewModel.collapsed)
    }

    @objc private func actionLabelDidTap() {
        guard let cellViewModel = cellViewModel,
              let action = cellViewModel.action,
              let promoCode = action.promoCode,
              let type = action.type,
              type == "promo" else {
            return
        }

        didTapActionLabel?(promoCode, action.pcpid)
    }

    @objc private func headerDidTap() {
        diTapHeader?()
    }

    func updateCollapseUI(collapsed: Bool) {
        if collapsed { showForExpand() } else { showForCollapse() }
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            collapsed ? self?.showForCollapse() : self?.showForExpand()
        })
    }

    func showForExpand() {
        titleLabel.textColor = UIColor.white
        iconView.layer.opacity = 1.0
        iconView.transform = CGAffineTransform(rotationAngle: .pi/4)
    }

    func showForCollapse() {
        titleLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        iconView.layer.opacity = 0.4
        iconView.transform = CGAffineTransform(rotationAngle: .pi*4)
    }
}

extension NewsFeedCell {
    /// return `true` => hide link
    /// return `false` => show link
    private func checkHideLinkIfNeed() -> Bool {
        let isFreeUser = !(cellViewModel?.isUserPro ?? false)
        guard isFreeUser,
              cellViewModel?.action?.type?.lowercased() == "promo" else {
            return false
        }
        return true
    }

    private func removeRefLink(`in` message: String) -> String {
        var returnMessage = message
        let bodyEndIndex = message.indices(of: "<p").last
        if let bodyEndIndex = bodyEndIndex {
            let pTag = String(message[bodyEndIndex...])
            if pTag.contains("ncta") {
                returnMessage = message.replacingOccurrences(of: pTag, with: "")
            }
        }

        return returnMessage
    }
}
