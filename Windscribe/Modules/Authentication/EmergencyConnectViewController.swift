//
//  EmergencyConnectViewController.swift
//  Windscribe
//
//  Created by Bushra Sagir on 19/04/23.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class EmergencyConnectViewController: UIViewController {
    // MARK: - UI properties

    @IBOutlet var closeButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var connectingLabel: UILabel!
    @IBOutlet var loader: UIActivityIndicatorView!

    // MARK: - State properties

    var viewmodal: EmergenyConnectViewModal!, logger: FileLogger!
    let disposeBag = DisposeBag()

    // MARK: - UI Events

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViews()
    }

    private func setupViews() {
        closeButton.setTitle("", for: .normal)
        let imageSize = CGSize(width: 25, height: 25)
        closeButton.layer.cornerRadius = 0.5 * closeButton.bounds.size.width
        closeButton.clipsToBounds = true
        closeButton.imageEdgeInsets = UIEdgeInsets(
            top: (closeButton.frame.size.height - imageSize.height) / 2,
            left: (closeButton.frame.size.width - imageSize.width) / 2,
            bottom: (closeButton.frame.size.height - imageSize.height) / 2,
            right: (closeButton.frame.size.width - imageSize.width) / 2
        )
        connectButton.layer.cornerRadius = 23
        connectButton.clipsToBounds = true
        connectButton.titleLabel?.font = UIFont.bold(size: 20)
        descriptionLabel.font = UIFont.text(size: 16)
        cancelButton.titleLabel?.font = UIFont.bold(size: 17)
        titleLabel.text = TextsAsset.connect
        cancelButton.setTitle(TextsAsset.cancel, for: .normal)
        connectingLabel.text = TextsAsset.connecting.uppercased()
    }

    private func bindViews() {
        viewmodal.state.bind { [self] state in
            switch state {
            case EmergencyConnectState.disconnected:
                hideLoadingView()
                self.descriptionLabel.text = TextsAsset.eConnectDescription
                self.connectButton.setTitle(TextsAsset.connect, for: .normal)
            case EmergencyConnectState.disconnecting:
                hideLoadingView()
                self.descriptionLabel.text = TextsAsset.eConnectDescription
                self.connectButton.setTitle(TextsAsset.disconnecting, for: .normal)
            case EmergencyConnectState.connecting:
                self.descriptionLabel.text = TextsAsset.connectedDescription
                self.connectButton.setTitle(TextsAsset.disconnect, for: .normal)
                showLoadingView()
            case EmergencyConnectState.connected:
                self.descriptionLabel.text = TextsAsset.connectedDescription
                self.connectButton.setTitle(TextsAsset.disconnect, for: .normal)
                hideLoadingView()
            }
        }.disposed(by: disposeBag)
        closeButton.rx.tap.bind {
            self.dismiss(animated: false)
        }.disposed(by: disposeBag)
        cancelButton.rx.tap.bind {
            self.dismiss(animated: false)
        }.disposed(by: disposeBag)
        connectButton.rx.tap.bind {
            self.viewmodal.connectButtonTapped()
        }.disposed(by: disposeBag)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func applicationWillEnterForeground() {
        viewmodal.appEnteredForeground()
    }

    // MARK: - Helper

    private func hideLoadingView() {
        DispatchQueue.main.async { [weak self] in
            self?.loader.isHidden = true
            self?.loader.stopAnimating()
            self?.descriptionLabel.isHidden = false
            self?.connectingLabel.isHidden = true
        }
    }

    private func showLoadingView() {
        DispatchQueue.main.async { [weak self] in
            self?.descriptionLabel.isHidden = true
            self?.loader.isHidden = false
            self?.loader.startAnimating()
            self?.connectingLabel.isHidden = false
        }
    }
}
