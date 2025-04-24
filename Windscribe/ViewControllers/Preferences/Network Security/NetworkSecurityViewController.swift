//
//  NetworkSecurityViewController.swift
//  Windscribe
//
//  Created by Thomas on 16/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RealmSwift
import RxSwift
import UIKit

class NetworkSecurityViewController: WSNavigationViewController {
    var router: NetworkSecurityRouter!, viewModel: NetworkSecurityViewModelType!, logger: FileLogger!

    // MARK: - UI elements

    lazy var autoSecureView = createAutoSecureView()
    lazy var headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.text(size: 14)
        lbl.numberOfLines = 0
        lbl.text = "Windscribe will auto-disconnect when you join a network tagged \"Unsecured\".".localize()
        return lbl
    }()

    lazy var headerView: UIView = {
        let view = UIView()
        view.addSubview(headerLabel)
        headerLabel.fillSuperview(padding: UIEdgeInsets(horizontalInset: 16, verticalInset: 12))
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 2
        return view
    }()

    lazy var currentNetworkView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            currentNetworkTitle,
            currentNetworkStackView
        ])
        stack.axis = .vertical
        return stack
    }()

    lazy var currentNetworkTitle = createHeader(text: TextsAsset.NetworkSecurity.currentNetwork)
    lazy var currentNetworkStackView: UIStackView = makeNetworkStackView()

    lazy var otherNetworkView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            otherNetworkTitle,
            otherNetworkStackView
        ])
        stack.axis = .vertical
        return stack
    }()

    lazy var otherNetworkTitle = createHeader(text: TextsAsset.NetworkSecurity.otherNetwork)
    lazy var otherNetworkStackView: UIStackView = makeNetworkStackView()

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Network Security View")
        setup()
        getNetworks()
        bindViews()
    }

    private func bindViews() {
        viewModel.isDarkMode.subscribe(onNext: {
            self.setupViews(isDark: $0)
            self.headerView.layer.borderColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0).cgColor
            self.headerLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }

    private func getNetworks() {
        viewModel.networks.observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [self] _ in
                    self.createListNetworkView()
                    let isOnline: Bool = ((try? self.viewModel.isOnline.value()) != nil)
                    self.currentNetworkView.isHidden = !isOnline
                }, onError: { [self] error in
                    self.logger.logE(self, "Realm network notification error \(error.localizedDescription)")
                }
            ).disposed(by: disposeBag)
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    private func setup() {
        setupFillLayoutView()
        titleLabel.text = TextsAsset.Preferences.networkSecurity
        layoutView.stackView.addArrangedSubviews([
            headerView,
            autoSecureView,
            currentNetworkView,
            otherNetworkView
        ])
        layoutView.stackView.setPadding(UIEdgeInsets(inset: 16))
        layoutView.stackView.spacing = 16
    }

    private func createAutoSecureView() -> ConnectionSecureView {
        let view = ConnectionSecureView(isDarkMode: viewModel.isDarkMode)
        let type = ConnectionSecure.autoSecure
        view.titleLabel.text = type.title
        view.subTitleLabel.text = type.description
        view.setImage(UIImage(named: SelectionViewType.autoConnection.asset))
        view.hideShowExplainIcon()
        view.switchButton.setStatus(viewModel.getAutoSecureNetworkStatus())
        view.connectionSecureViewSwitchAcction = { [weak self] in
            self?.viewModel.updateAutoSecureNetworkStatus()
        }
        return view
    }

    private func makeNetworkStackView() -> UIStackView {
        let vw = UIStackView(arrangedSubviews: [otherNetworkTitle])
        vw.axis = .vertical
        let bg = UIView()
        bg.layer.cornerRadius = 8
        vw.addSubview(bg)
        bg.fillSuperview()
        bg.sendToBack()

        viewModel.isDarkMode.subscribe(onNext: {
            bg.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
        return vw
    }

    private func createListNetworkView() {
        viewModel.currentNetwork.distinctUntilChanged().bind(onNext: { [self] network in
            currentNetworkStackView.removeAllArrangedSubviews()
            otherNetworkStackView.removeAllArrangedSubviews()
            let currentSSID = network?.name
            guard let lst = try? self.viewModel.networks.value() else { return }
            var prevOtherCell: NetworkCellView?
            var currentNetworkFound = false
            var otherNetworkFound = false
            for (_, network) in lst.enumerated() {
                // Only show networks that have an SSID
                guard !network.SSID.isEmpty else { continue }
                let vw = NetworkCellView(isDarkMode: viewModel.isDarkMode)
                vw.bindData(network)
                vw.delegate = self
                if network.SSID == currentSSID {
                    currentNetworkFound = true
                    currentNetworkStackView.addArrangedSubview(vw)
                } else {
                    otherNetworkFound = true
                    if prevOtherCell != nil {
                        vw.addTopDivider()
                    }
                    otherNetworkStackView.addArrangedSubview(vw)
                    prevOtherCell = vw
                }
            }
            currentNetworkTitle.isHidden = !currentNetworkFound
            otherNetworkTitle.isHidden = !otherNetworkFound
        }).disposed(by: disposeBag)
    }

    private func createHeader(text: String) -> UIView {
        let vw = UIView()
        let lbl = UILabel()
        lbl.font = UIFont.bold(size: 11)
        lbl.text = text.uppercased()
        vw.addSubview(lbl)
        lbl.addCharacterSpacing(kernValue: 1.3)
        lbl.fillSuperview(padding: UIEdgeInsets(inset: 16))

        viewModel.isDarkMode.subscribe(onNext: { isDark in
            lbl.textColor = isDark ? .whiteWithOpacity(opacity: 0.5) : .midnightWithOpacity(opacity: 0.5)
        }).disposed(by: disposeBag)
        return vw
    }
}

extension NetworkSecurityViewController: NetworkCellViewDelegate {
    func networkCellViewDidSelect(_ network: WifiNetwork) {
        router.routeTo(to: RouteID.network(with: network), from: self)
    }
}

// MARK: - NetworkCellView

protocol NetworkCellViewDelegate: AnyObject {
    func networkCellViewDidSelect(_ network: WifiNetwork)
}

class NetworkCellView: UIStackView {
    private(set) var network: WifiNetwork?
    let disposeBag = DisposeBag()
    var isDarkMode: BehaviorSubject<Bool>

    weak var delegate: NetworkCellViewDelegate?
    init(isDarkMode: BehaviorSubject<Bool>) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews() {
        isDarkMode.subscribe(onNext: {
            self.lblName.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.lblSecureStatus.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }

    private func setup() {
        addArrangedSubviews([
            lblName,
            UIView(),
            lblSecureStatus,
            iconArrow
        ])
        axis = .horizontal
        setPadding(UIEdgeInsets(inset: 16))
        spacing = 8
        rx.anyGesture(.tap()).skip(1).subscribe(onNext: { _ in
            self.handleSelect()
        }).disposed(by: disposeBag)
    }

    private lazy var lblName: UILabel = {
        let lbl = UILabel()
        lbl.font = .bold(size: 16)
        return lbl
    }()

    private lazy var lblSecureStatus: UILabel = {
        let lbl = UILabel()
        lbl.font = .text(size: 16)
        return lbl
    }()

    private lazy var iconArrow: UIImageView = {
        let imv = UIImageView()
        imv.image = UIImage(named: ImagesAsset.rightArrow)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        imv.layer.opacity = 0.5
        imv.contentMode = .scaleAspectFit
        imv.anchor(width: 16, height: 16)

        isDarkMode.subscribe(onNext: { _ in
        }).disposed(by: disposeBag)
        return imv
    }()

    func bindData(_ data: WifiNetwork) {
        network = data
        lblName.setTextWithOffSet(text: data.SSID)
        lblSecureStatus.text = TextsAsset.NetworkSecurity.untrusted
        if data.status {
            lblSecureStatus.text = TextsAsset.NetworkSecurity.trusted
        }
    }

    @objc private func handleSelect() {
        if let network = network {
            delegate?.networkCellViewDidSelect(network)
        }
    }
}

extension UILabel {
    func addCharacterSpacing(kernValue: Double = 1.15) {
        guard let text = text, !text.isEmpty else { return }
        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
        attributedText = string
    }
}
