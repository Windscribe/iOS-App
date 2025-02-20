//
//	AccountEditCell.swift
//	Windscribe
//
//	Created by Thomas on 21/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

class AccountEditCell: WSTouchTableViewCell {
    private var disposeBag = DisposeBag()

    lazy var titleLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.bold(size: 16)
        label.layer.opacity = 0.5
        return label
    }()

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.opacity = 0.5
        imageView.makeHeightAnchor(equalTo: 18)
        imageView.makeWidthAnchor(equalTo: 16)
        return imageView
    }()

    lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.08)
        view.layer.cornerRadius = 8
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(wrapperView)
        wrapperView.makeTopAnchor(constant: 16)
        wrapperView.makeLeadingAnchor()
        wrapperView.makeTrailingAnchor()
        wrapperView.makeBottomAnchor()

        wrapperView.addSubview(titleLbl)
        titleLbl.makeTopAnchor(constant: 16)
        titleLbl.makeLeadingAnchor(constant: 16)
        titleLbl.makeBottomAnchor(constant: 16)

        wrapperView.addSubview(iconView)
        iconView.centerYAnchor.constraint(equalTo: titleLbl.centerYAnchor).isActive = true
        iconView.makeTrailingAnchor(constant: 16)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configNormal() {
        titleLbl.layer.opacity = 0.5
        iconView.layer.opacity = 0.5
    }

    override func configHighlight() {
        titleLbl.layer.opacity = 1
        iconView.layer.opacity = 1
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    private func updateView() {
        titleLbl.text = accoutItem.title
    }

    func bindView(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.titleLbl.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
            self.iconView.image = ThemeUtils.prefRightIcon(isDarkMode: $0)
            wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }

    var accoutItem: AccountItemCell! {
        didSet {
            updateView()
        }
    }
}

class ArrowRowView: WSTouchStackView {
    var rowTitle: String

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 16)
        lbl.layer.opacity = 0.5
        lbl.text = rowTitle
        return lbl
    }()

    private lazy var arrowImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.opacity = 0.5
        imageView.anchor(width: 16, height: 16)
        return imageView
    }()

    lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.whiteWithOpacity(opacity: 0.08)
        view.layer.cornerRadius = 8
        return view
    }()

    private let disposeBag = DisposeBag()

    init(rowTitle: String, isDarkMode: BehaviorSubject<Bool>) {
        self.rowTitle = rowTitle
        super.init(frame: .zero)
        setup()
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
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
        addSubview(wrapperView)
        wrapperView.fillSuperview()
        addArrangedSubviews([
            titleLabel,
            UIView(),
            arrowImage
        ])
        setPadding(UIEdgeInsets(inset: 16))
        spacing = 4
        layer.cornerRadius = 8
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) { isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        self.titleLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        self.arrowImage.image = ThemeUtils.prefRightIcon(isDarkMode: $0)
        wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
    }).disposed(by: disposeBag)
    }
}

protocol LazyViewDelegate: AnyObject {
    func lazyViewDidSelect()
}

class LazyTableViewCell: UITableViewCell {
    var lazyView: HelpView?
    private lazy var viewModel = Assembler.resolve(AccountViewModelType.self)
    weak var delegate: LazyViewDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        lazyView = HelpView(item: HelpItem(title: TextsAsset.Account.lazyLogin,
                                           subTitle: TextsAsset.Account.lazyLoginDescription),
                            type: .navigation,
                            delegate: self,
                            isDarkMode: viewModel.isDarkMode)
        contentView.addSubview(lazyView!)
        lazyView?.translatesAutoresizingMaskIntoConstraints = false

        lazyView?.makeLeadingAnchor(constant: 0)
        lazyView?.makeTrailingAnchor(constant: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LazyTableViewCell: HelpViewDelegate {
    func helpViewDidSelect(_: HelpView) {
        delegate?.lazyViewDidSelect()
    }
}

protocol VoucherDelegate: AnyObject {
    func voucherViewDidSelect()
}

class VoucherCodeTableViewCell: UITableViewCell {
    var voucherView: HelpView?
    private lazy var viewModel = Assembler.resolve(AccountViewModelType.self)
    weak var delegate: VoucherDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        voucherView = HelpView(item: HelpItem(title: TextsAsset.voucherCode,
                                              subTitle: TextsAsset.Account.voucherCodeDescription),
                               type: .navigation,
                               delegate: self,
                               isDarkMode: viewModel.isDarkMode)
        contentView.addSubview(voucherView!)
        voucherView?.translatesAutoresizingMaskIntoConstraints = false

        voucherView?.makeLeadingAnchor(constant: 0)
        voucherView?.makeTrailingAnchor(constant: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VoucherCodeTableViewCell: HelpViewDelegate {
    func helpViewDidSelect(_: HelpView) {
        delegate?.voucherViewDidSelect()
    }
}
