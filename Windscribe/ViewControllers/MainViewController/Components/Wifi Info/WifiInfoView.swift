//
//  WifiInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture

protocol WifiInfoViewModelType {
    var trustedNetworkImage: String { get }
    var isBlur: Bool { get }
    var unknownWifiTriggerSubject: PublishSubject<Void> { get }

    func nameLabelTapped(networkName: String?) -> Bool?
}

class WifiInfoViewModel: WifiInfoViewModelType {
    let preferences: Preferences
    let unknownWifiTriggerSubject = PublishSubject<Void>()
    let disposeBag = DisposeBag()

    var trustedNetworkImage: String {
        if let status = WifiManager.shared.getConnectedNetwork()?.status {
            if status == true {
                return ImagesAsset.wifiUnsecure
            } else {
                return ImagesAsset.wifi
            }
        } else {
            return ImagesAsset.wifi
        }
    }

    var isBlur: Bool {
        return preferences.getBlurNetworkName() ?? false
    }

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func nameLabelTapped(networkName: String?) -> Bool? {
        if networkName == TextsAsset.NetworkSecurity.unknownNetwork {
            unknownWifiTriggerSubject.onNext(())
            return nil
        } else {
            preferences.saveBlurNetworkName(bool: !(preferences.getBlurNetworkName() ?? false))
            return (preferences.getBlurNetworkName() ?? false)
        }
    }
}

class WifiInfoView: UIView {
    let disposeBag = DisposeBag()
    let wifiTriggerSubject = PublishSubject<WifiNetwork>()
    let unknownWifiTriggerSubject = PublishSubject<Void>()

    var viewModel: WifiInfoViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    var actionButton = UIButton()
    var paddingView = UIView()
    var nameLabel = BlurredLabel()
    var trustedIcon = UIImageView()
    var actionImage = UIImageView()
    var stackView = UIStackView()
    var nameLabelSpacerView = UIView()
    private var network: WifiNetwork?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    func updateWifiName(name: String) {
        nameLabel.text = name
        updateActionVivibility()
        // Force layout recalculation to apply compression resistance priorities
        setNeedsLayout()
    }

    private func bindViewModel() {
        trustedIcon.image = UIImage(named: viewModel.trustedNetworkImage)?
            .withRenderingMode(.alwaysTemplate)

        nameLabel.isBlurring = viewModel.isBlur

        // Track when double tap occurs to prevent single tap
        var isDoubleTapInProgress = false

        // Double tap for blur toggle (known network only)
        nameLabel.rx.anyGesture(.tap(configuration: { gestureRecognizer, _ in
            gestureRecognizer.numberOfTapsRequired = 2
        })).skip(1).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            isDoubleTapInProgress = true
            if nameLabel.text != TextsAsset.NetworkSecurity.unknownNetwork {
                let preferences = (viewModel as? WifiInfoViewModel)?.preferences
                preferences?.saveBlurNetworkName(bool: !(preferences?.getBlurNetworkName() ?? false))
                nameLabel.isBlurring = preferences?.getBlurNetworkName() ?? false
            }
            // Reset flag after delay longer than debounce time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isDoubleTapInProgress = false
            }
        }).disposed(by: disposeBag)

        // Single tap for location permission popup (unknown network) or network details (known network)
        nameLabel.rx.anyGesture(.tap()).skip(1)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                // Don't fire if double tap is in progress
                guard !isDoubleTapInProgress else { return }
                if nameLabel.text == TextsAsset.NetworkSecurity.unknownNetwork {
                    viewModel.unknownWifiTriggerSubject.onNext(())
                } else {
                    guard let network = self.network else { return }
                    self.wifiTriggerSubject.onNext(network)
                }
            }).disposed(by: disposeBag)

        actionButton.rx.tap.bind { [weak self] _ in
            guard let network = self?.network else { return }
            self?.wifiTriggerSubject.onNext(network)
        }.disposed(by: disposeBag)

        viewModel.unknownWifiTriggerSubject.subscribe { [weak self] _ in
            self?.unknownWifiTriggerSubject.onNext(())
        }.disposed(by: disposeBag)
    }

    func renderBlurSpacedLabel(isBlurred: Bool) {
        if isBlurred {
            nameLabel.isBlurring = true
        } else {
            nameLabel.isBlurring = false
        }
    }

    func updateNetwork(network: WifiNetwork?) {
        self.network = network
        trustedIcon.image = UIImage(named: viewModel.trustedNetworkImage)?
            .withRenderingMode(.alwaysTemplate)
        updateActionVivibility()
    }

    private func updateActionVivibility() {
        let isNetwork = nameLabel.text != TextsAsset.NetworkSecurity.unknownNetwork &&
        nameLabel.text != TextsAsset.noNetworksAvailable &&
        network != nil
        actionButton.isHidden = !isNetwork
    }

    private func addViews() {
        nameLabel.font = UIFont.medium(size: 16)
        nameLabel.textColor = .whiteWithOpacity(opacity: 0.7)
        nameLabel.isUserInteractionEnabled = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        nameLabel.lineBreakMode = .byTruncatingTail
        // Set low horizontal compression resistance so this label compresses before ipInfoView gets squeezed
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.text = TextsAsset.NetworkSecurity.unknownNetwork

        trustedIcon = UIImageView()
        trustedIcon.contentMode = .scaleAspectFit
        trustedIcon.image = UIImage(named: ImagesAsset.wifi)?.withRenderingMode(.alwaysTemplate)
        trustedIcon.tintColor = .whiteWithOpacity(opacity: 0.7)

        actionImage.image = UIImage(named: ImagesAsset.smallWhiteRightArrow)
        actionImage.setImageColor(color: .whiteWithOpacity(opacity: 0.7))

        stackView.addArrangedSubviews([paddingView, trustedIcon, nameLabelSpacerView, nameLabel, actionButton])
        stackView.axis = .horizontal
        actionButton.addSubview(actionImage)
        addSubview(stackView)
    }

    private func setLayout() {
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        trustedIcon.translatesAutoresizingMaskIntoConstraints = false
        nameLabelSpacerView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        trustedIcon.translatesAutoresizingMaskIntoConstraints = false
        actionImage.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackView
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),

            // paddingView
            paddingView.heightAnchor.constraint(equalToConstant: 24),
            paddingView.widthAnchor.constraint(equalToConstant: 5),

            // trustedIcon
            trustedIcon.heightAnchor.constraint(equalToConstant: 24),
            trustedIcon.widthAnchor.constraint(equalToConstant: 24),

            // nameLabelSpacerView - aligns network name with location names in list below
            nameLabelSpacerView.widthAnchor.constraint(equalToConstant: 12),

            // actionImage
            actionImage.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            actionImage.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor, constant: -4),
            actionImage.heightAnchor.constraint(equalToConstant: 12),
            actionImage.widthAnchor.constraint(equalToConstant: 12),

            // actionButton
            actionButton.heightAnchor.constraint(equalToConstant: 24),
            actionButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
}
