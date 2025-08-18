//
//  ConnectButtonView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 26/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import QuartzCore

protocol ConnectButtonViewModelType {
    var statusSubject: BehaviorSubject<ConnectionState?> { get }
    func refreshConnectingState()
}

class ConnectButtonViewModel: ConnectButtonViewModelType {
    let statusSubject = BehaviorSubject<ConnectionState?>(value: nil)

    let disposeBag = DisposeBag()

    init(vpnManager: VPNManager) {
        vpnManager.getStatus().subscribe(onNext: { state in
            self.statusSubject.onNext(ConnectionState.state(from: state))
        }).disposed(by: disposeBag)
    }

    func refreshConnectingState() {
        statusSubject.onNext(.connecting)
    }
}

class ConnectButtonView: UIView {
    let disposeBag = DisposeBag()
    let connectTriggerSubject = PublishSubject<Void>()

    private var isButtonRotated = false

    var viewModel: ConnectButtonViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    var ringImageView = UIImageView()
    var centralImageContainerView = UIView()
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
                let animationTime: CGFloat = 0.25
                UIView.animate(withDuration: animationTime) {
                    self.ringImageView.isHidden = state.connectButtonRingIsHidden
                    self.ringImageView.image = UIImage(named: state.connectButtonRing)
                    self.ringImageView.setImageColor(color: state.connectButtonRingColor)
                }

                if state.isConnectButtonRingRotated != self.isButtonRotated {
                    let rotationAngle: CGFloat = state.isConnectButtonRingRotated ? .pi/2 : 0
                    UIView.animate(withDuration: TimeInterval(animationTime)) {
                        self.centralImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                        self.centralImageContainerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                    }
                    self.isButtonRotated = state.isConnectButtonRingRotated
                }
                if [.connected, .testing].contains(state) {
                    self.ringImageView.stopRotating()
                } else {
                    // Check if ring layer is already rotating to prevent glitch
                    let isCurrentlyRotating = self.ringImageView.layer.animationKeys()?.contains("rotationanimationkey") == true
                    if !isCurrentlyRotating {
                        self.ringImageView.rotate()
                    }
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
        centralImageContainerView.addSubview(centralImageView)
        addSubview(ringImageView)
        addSubview(centralImageContainerView)
        addSubview(connectButton)
    }

    private func setLayout() {
        ringImageView.translatesAutoresizingMaskIntoConstraints = false
        centralImageContainerView.translatesAutoresizingMaskIntoConstraints = false
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

            // centralImageContainerView
            centralImageContainerView.centerYAnchor.constraint(equalTo: ringImageView.centerYAnchor),
            centralImageContainerView.centerXAnchor.constraint(equalTo: ringImageView.centerXAnchor),
            centralImageContainerView.heightAnchor.constraint(equalToConstant: centralSize),
            centralImageContainerView.widthAnchor.constraint(equalToConstant: centralSize),

            // centralImageView
            centralImageView.centerYAnchor.constraint(equalTo: centralImageContainerView.centerYAnchor),
            centralImageView.centerXAnchor.constraint(equalTo: centralImageContainerView.centerXAnchor),
            centralImageView.heightAnchor.constraint(equalTo: centralImageContainerView.heightAnchor),
            centralImageView.widthAnchor.constraint(equalTo: centralImageContainerView.widthAnchor),

            // connectButton
            connectButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            connectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            connectButton.heightAnchor.constraint(equalTo: heightAnchor),
            connectButton.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
