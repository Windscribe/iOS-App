//
//  ConnectButtonView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 26/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol ConnectButtonViewModelType {
    var statusSubject: BehaviorSubject<ConnectionState?> { get }
}

class ConnectButtonViewModel: ConnectButtonViewModelType {
    let statusSubject = BehaviorSubject<ConnectionState?>(value: nil)

    let disposeBag = DisposeBag()

    init(vpnManager: VPNManager) {
        vpnManager.getStatus().subscribe(onNext: { state in
            self.statusSubject.onNext(ConnectionState.state(from: state))
        }).disposed(by: disposeBag)
    }
}

class ConnectButtonView: UIView {
    let disposeBag = DisposeBag()
    let connectTriggerSubject = PublishSubject<Void>()

    var viewModel: ConnectButtonViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    var ringImageView = UIImageView()
    var centralImageView = UIImageView()
    var connectButton = UIButton()

    var buttonSize: CGFloat {
        if UIDevice.current.isIphone6() {
            return 84
        } else if UIDevice.current.isIphone5orLess() {
            return 74
        }
        return 96
    }

    var centralSize: CGFloat {
        if UIDevice.current.isIphone6() {
            return 72
        } else if UIDevice.current.isIphone5orLess() {
            return 62
        }
        return 80
    }

    var rightPadding: CGFloat {
        if UIDevice.current.isIphone6() || UIDevice.current.isIphone5orLess() {
            return -24
        }
        return -16
    }

    var topPadding: CGFloat {
        if UIScreen.hasTopNotch {
            return 50
        } else if UIDevice.current.isIpad {
            return 44
        }
        return 44
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func bindViewModel() {
        viewModel.statusSubject.subscribe { [weak self] state in
            guard let self = self, let state = state else { return }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.ringImageView.isHidden = state.connectButtonRingIsHidden
                    self.ringImageView.image = UIImage(named: state.connectButtonRing)
                    self.ringImageView.setImageColor(color: state.connectButtonRingColor)
                    self.centralImageView.image = UIImage(named: state.connectButton)
                }
                if [.connected, .testing].contains(state) {
                    self.ringImageView.stopRotating()
                } else {
                    self.ringImageView.rotate()
                }
            }
        }.disposed(by: disposeBag)
        connectButton.rx.tap.bind {
            self.connectTriggerSubject.onNext(())
        }.disposed(by: disposeBag)
    }

    private func addViews() {
        ringImageView.image = UIImage(named: ImagesAsset.connectButtonRing)
        ringImageView.isHidden = true
        centralImageView.image = UIImage(named: ImagesAsset.disconnectedButton)
        addSubview(ringImageView)
        addSubview(centralImageView)
        addSubview(connectButton)
    }

    private func setLayout() {
        ringImageView.translatesAutoresizingMaskIntoConstraints = false
        centralImageView.translatesAutoresizingMaskIntoConstraints = false
        connectButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // ringImageView
            ringImageView.topAnchor.constraint(equalTo: topAnchor),
            ringImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ringImageView.rightAnchor.constraint(equalTo: rightAnchor),
            ringImageView.leftAnchor.constraint(equalTo: leftAnchor),
            ringImageView.heightAnchor.constraint(equalToConstant: buttonSize),
            ringImageView.widthAnchor.constraint(equalToConstant: buttonSize),

            // centralImageView
            centralImageView.centerYAnchor.constraint(equalTo: ringImageView.centerYAnchor),
            centralImageView.centerXAnchor.constraint(equalTo: ringImageView.centerXAnchor),
            centralImageView.heightAnchor.constraint(equalToConstant: centralSize),
            centralImageView.widthAnchor.constraint(equalToConstant: centralSize),

            // connectButton
            connectButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            connectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            connectButton.heightAnchor.constraint(equalTo: heightAnchor),
            connectButton.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
