//
//  HelpView.swift
//  Windscribe
//
//  Created by Thomas on 26/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import RxSwift

protocol HelpViewDelegate: AnyObject {
    func helpViewDidSelect(_ sender: HelpView)
}

class HelpView: UIStackView {
    private(set) var item: HelpItem
    private(set) var type: HelpHeaderType
    weak var delegate: HelpViewDelegate?
    private let isDarkMode: BehaviorSubject<Bool>
    private let disposeBag = DisposeBag()

    var listSubView: [UIView] = [] {
        didSet {
            reloadContenStack()
        }
    }

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView])
        stack.axis = .vertical
        stack.addSubview(wrapperView)
        wrapperView.fillSuperview(padding: UIEdgeInsets(inset: 2))
        wrapperView.sendToBack()
        return stack
    }()

    private lazy var headerView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [header])
        stack.axis = .vertical
        stack.setPadding(UIEdgeInsets(inset: 16))
        stack.isUserInteractionEnabled = true
        let gs = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        stack.addGestureRecognizer(gs)
        return stack
    }()

    lazy var header = HelpHeaderView(item: item, type: type, isDarkMode: isDarkMode)

    private lazy var footerView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [footerLabel])
        stack.axis = .vertical
        stack.setPadding(UIEdgeInsets(inset: 16))
        return stack
    }()

    private lazy var footerLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.text(size: 14)
        lbl.text = item.subTitle
        lbl.numberOfLines = 0
        lbl.layer.opacity = 0.5
        return lbl
    }()

    private lazy var borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    init(item: HelpItem, type: HelpHeaderType, delegate: HelpViewDelegate? = nil, isDarkMode: BehaviorSubject<Bool>) {
        self.type = type
        self.item = item
        self.delegate = delegate
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .vertical
        addArrangedSubviews([
            contentStack
        ])

        if !item.subTitle.isEmpty {
            addArrangedSubview(footerView)
            addSubview(borderView)
            borderView.fillSuperview()
            borderView.sendToBack()
        }
    }

    private func reloadContenStack() {
        contentStack.removeAllArrangedSubviews()
        contentStack.addArrangedSubview(headerView)
        listSubView.forEach {
            contentStack.addArrangedSubview($0)
        }
    }

    @objc private func didTapView() {
        delegate?.helpViewDidSelect(self)
    }

    private func bindViews() {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: { [weak self] in
            guard let self = self else { return }
            self.wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            self.footerLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.borderView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0).cgColor
        }).disposed(by: disposeBag)
    }
}

// MARK: - HelpHeaderType
enum HelpHeaderType {
    case navigation
    case action
}

// MARK: - HelpHeaderView
class HelpHeaderView: WSTouchStackView {
    private(set) var item: HelpItem
    private(set) var type: HelpHeaderType

    private lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: item.icon)?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.anchor(width: 16, height: 16)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 16)
        lbl.layer.opacity = 0.5
        lbl.setTextWithOffSet(text: item.title)
        return lbl
    }()

    private lazy var arrowImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.opacity = 0.5
        image.anchor(width: 16, height: 16)
        return image
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.layer.opacity = 0.5
        indicator.isHidden = true
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    private lazy var statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.text(size: 16)
        lbl.isHidden = true
        return lbl
    }()
    private let disposeBag = DisposeBag()

    init(item: HelpItem, type: HelpHeaderType, isDarkMode: BehaviorSubject<Bool>) {
        self.type = type
        self.item = item
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configNormal() {
        titleLabel.layer.opacity = 0.5
        arrowImage.layer.opacity = 0.5
    }
    override func configHighlight() {
        titleLabel.layer.opacity = 1
        arrowImage.layer.opacity = 1
    }

    private func setup() {
        axis = .horizontal
        spacing = 16
        addArrangedSubviews([
            iconImage, titleLabel, UIView(), statusLabel, loadingIndicator
        ])
        if type == .navigation {
            addArrangedSubview(arrowImage)
        }
    }

    func updateTitle(_ title: String, font: UIFont) {
        self.titleLabel.font = font
        self.titleLabel.setTextWithOffSet(text: title)
    }

    func updateStatus(_ text: String) {
        self.statusLabel.text = text
    }

    func showLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }

    func completeLoading(_ error: String?) {
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        if error == nil {
            statusLabel.isHidden = false
        } else {
            statusLabel.isHidden = true
        }
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: { [weak self] in
            guard let self = self else { return }
            self.iconImage.tintColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.arrowImage.image = ThemeUtils.prefRightIcon(isDarkMode: $0)
            self.statusLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }
}

protocol HelpSubRowViewDelegate: AnyObject {
    func helpSubRowViewDidTap(_ sender: HelpSubRowView)
}
// MARK: - HelpSubRowView
class HelpSubRowView: WSTouchStackView {
    private(set) var header: String
    weak var delegate: HelpSubRowViewDelegate?
    private let disposeBag = DisposeBag()

    init(header: String, isDarkMode: BehaviorSubject<Bool>, delegate: HelpSubRowViewDelegate? = nil) {
        self.header = header
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.text(size: 16)
        lbl.layer.opacity = 0.5
        lbl.setTextWithOffSet(text: header)
        return lbl
    }()

    private lazy var arrowImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.opacity = 0.5
        image.anchor(width: 16, height: 16)
        return image
    }()

    private func setup() {
        axis = .horizontal
        spacing = 16
        addArrangedSubviews([
            titleLabel, UIView(), arrowImage
        ])
        setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 16))
        isUserInteractionEnabled = true
        let gs = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(gs)
    }

    override func configNormal() {
        titleLabel.layer.opacity = 0.5
        arrowImage.layer.opacity = 0.5
    }
    override func configHighlight() {
        titleLabel.layer.opacity = 1
        arrowImage.layer.opacity = 1
    }

    @objc private func didTapView() {
        delegate?.helpSubRowViewDidTap(self)
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: { [weak self] in
            guard let self = self else { return }
            self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.arrowImage.image = ThemeUtils.prefRightIcon(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }
}
