//
//  IPInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class IPInfoView: UIView {
    let disposeBag = DisposeBag()
    var viewModel: IPInfoViewModelType! {
        didSet {
            bindViewModel()
        }
    }

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

    var favoriteButton = UIButton()
    var refreshButton = UIButton()
    var closeButton = UIButton()
    var openButton = UIButton()
    var ipLabel = BlurredLabel()
    var stackView = UIStackView()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func showSecureIPAddressState(ipAddress: String) {
        DispatchQueue.main.async {
            let formattedIP = ipAddress.formatIpAddress().maxLength(length: 15)
            UIView.animate(withDuration: 0.25) {
                self.ipLabel.text = formattedIP.isEmpty ? "---.---.---.---" : formattedIP
            }
        }
    }

    private func bindViewModel() {
        ipLabel.isBlurring = viewModel.isBlurStaticIpAddress

        viewModel.ipAddressSubject.bind(onNext: {
            self.showSecureIPAddressState(ipAddress: $0)
        }).disposed(by: disposeBag)

        ipLabel.rx.anyGesture(.tap()).skip(1).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.markBlurStaticIpAddress(isBlured: !viewModel.isBlurStaticIpAddress)
            self.ipLabel.isBlurring = viewModel.isBlurStaticIpAddress
        }).disposed(by: disposeBag)

        openButton.rx.tap.bind { [weak self] _ in
            guard let self = self else { return }
            self.stackView.spacing = 8
            self.favoriteButton.isHidden = false
            self.refreshButton.isHidden = false
            self.closeButton.isHidden = false

            self.openButton.isHidden = true
            self.ipLabel.isHidden = true
        }.disposed(by: disposeBag)

        closeButton.rx.tap.bind { [weak self] _ in
            guard let self = self else { return }
            self.stackView.spacing = 0
            self.favoriteButton.isHidden = true
            self.refreshButton.isHidden = true
            self.closeButton.isHidden = true

            self.openButton.isHidden = false
            self.ipLabel.isHidden = false
        }.disposed(by: disposeBag)
    }

    private func addViews() {
        ipLabel.isUserInteractionEnabled = true
        ipLabel.tag = 0
        ipLabel.font = UIFont.medium(size: 16)
        ipLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.7)
        ipLabel.textAlignment = .right

        favoriteButton.setImage(UIImage(named: ImagesAsset.IPMenu.save), for: .normal)
        refreshButton.setImage(UIImage(named: ImagesAsset.IPMenu.refresh), for: .normal)
        closeButton.setImage(UIImage(named: ImagesAsset.IPMenu.close), for: .normal)
        openButton.setImage(UIImage(named: ImagesAsset.IPMenu.open), for: .normal)

        favoriteButton.imageView?.setImageColor(color: .white)
        refreshButton.imageView?.setImageColor(color: .white)
        closeButton.imageView?.setImageColor(color: .white)
        openButton.imageView?.setImageColor(color: .white)

        favoriteButton.isHidden = true
        refreshButton.isHidden = true
        closeButton.isHidden = true
        openButton.isHidden = true

        stackView.addArrangedSubviews([ipLabel])
        stackView.axis = .horizontal
        addSubview(stackView)
    }

    private func setLayout() {
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackView
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),

            // favoriteButton
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),

            // refreshButton
            refreshButton.heightAnchor.constraint(equalToConstant: 32),
            refreshButton.widthAnchor.constraint(equalToConstant: 32),

            // closeButton
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            closeButton.widthAnchor.constraint(equalToConstant: 32),

            // openButton
            openButton.heightAnchor.constraint(equalToConstant: 32),
            openButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }
}
