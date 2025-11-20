//
//  IPInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

class IPInfoView: UIView {
    private var cancellables = Set<AnyCancellable>()
    var actionFailedSubject = PassthroughSubject<BridgeApiPopupType, Never>()
    var animateFavoriteSubject = PassthroughSubject<Void, Never>()

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
    var ipLabel = SlotMachineLabel()
    var stackView = UIStackView()

    private var isFirstIPUpdate = true
    private var rollingTask: DispatchWorkItem?
    private var currentIPText: String = ""

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
            let displayIP = formattedIP.isEmpty ? "---.---.---.---" : formattedIP

            // Store current IP for rolling animation
            self.currentIPText = displayIP

            // Don't animate the first IP update
            let shouldAnimate = !self.isFirstIPUpdate
            self.ipLabel.setText(displayIP, animated: shouldAnimate)

            if self.isFirstIPUpdate {
                self.isFirstIPUpdate = false
            }
        }
    }

    @objc private func handleDoubleTap() {
        viewModel.markBlurStaticIpAddress(isBlured: !viewModel.isBlurStaticIpAddress)
        ipLabel.isBlurring = viewModel.isBlurStaticIpAddress
    }

    private func bindViewModel() {
        ipLabel.isBlurring = viewModel.isBlurStaticIpAddress
        actionFailedSubject = viewModel.actionFailedSubject

        viewModel.actionFailedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavourited in
                guard let self = self else { return }
                self.rollingTask?.cancel()
                self.rollingTask = nil
            }
            .store(in: &cancellables)
        
        viewModel.ipAddressSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ipAddress in
                guard let self = self else { return }

                // Cancel rolling animation when new IP arrives
                // This stops the continuous rolling loop and allows the final
                // animation to play from current IP to the new IP
                self.rollingTask?.cancel()
                self.rollingTask = nil

                self.showSecureIPAddressState(ipAddress: ipAddress)
            }
            .store(in: &cancellables)

        viewModel.areActionsAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] actionEnabled in
                guard let self = self else { return }
                if !actionEnabled && !self.favoriteButton.isHidden {
                    closeMenu()
                }
                UIView.animate(withDuration: 0.3) {
                    self.openButton.alpha = actionEnabled ? 1.0 : 0.5
                }
                self.openButton.isEnabled = actionEnabled
            }
            .store(in: &cancellables)

        // Add double-tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        ipLabel.addGestureRecognizer(doubleTapGesture)

        viewModel.isFavouritedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavourited in
                guard let self = self else { return }
                favoriteButton.setImage(setFavoriteButtonImage(isFavourited: isFavourited),for: .normal)
            }
            .store(in: &cancellables)

        openButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.stackView.spacing = 8
            self.favoriteButton.isHidden = false
            self.refreshButton.isHidden = false
            self.closeButton.isHidden = false

            self.openButton.isHidden = true
            self.ipLabel.isHidden = true
        }, for: .touchUpInside)

        closeButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.closeMenu()
        }, for: .touchUpInside)

        favoriteButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            viewModel.runHapticFeedback(level: .medium)
            viewModel.saveIp()

            // Notify to animate bottom favorite button
            self.animateFavoriteSubject.send()

            // Animate favorite button with grow/shrink effect
            self.animateHeartButton(self.favoriteButton) {
                // Close menu after animation completes
                self.closeMenu()
            }
        }, for: .touchUpInside)

        refreshButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            viewModel.runHapticFeedback(level: .medium)

            // Start continuous rolling animation until new IP arrives
            // This creates a rolling loop effect that provides instant visual feedback
            // and continues until either:
            // 1. The new IP arrives from the API (success)
            // 2. The rotation fails (error)
            // The rolling is implemented by repeatedly animating the current IP to itself,
            // creating a continuous slot machine effect that hides network latency.
            func rollOnce() {
                if !self.currentIPText.isEmpty && !self.currentIPText.contains("-") {
                    self.ipLabel.setText(self.currentIPText, animated: true)
                }

                // Schedule next roll after animation duration (1.2 seconds)
                let task = DispatchWorkItem { rollOnce() }
                self.rollingTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
            }

            // Cancel any previous rolling task and start fresh
            self.rollingTask?.cancel()
            rollOnce()

            viewModel.rotateIp()
            self.closeMenu()
        }, for: .touchUpInside)
    }

    private func closeMenu() {
        self.stackView.spacing = 0
        self.favoriteButton.isHidden = true
        self.refreshButton.isHidden = true
        self.closeButton.isHidden = true

        self.openButton.isHidden = false
        self.ipLabel.isHidden = false
    }

    private func animateHeartButton(_ button: UIButton, completion: @escaping () -> Void) {
        // Short, smooth grow/shrink animation
        let growScale: CGFloat = 1.3
        let animationDuration: TimeInterval = 0.15

        UIView.animate(withDuration: animationDuration, animations: {
            button.transform = CGAffineTransform(scaleX: growScale, y: growScale)
        }) { _ in
            UIView.animate(withDuration: animationDuration, animations: {
                button.transform = .identity
            }) { _ in
                completion()
            }
        }
    }

    private func addViews() {
        ipLabel.translatesAutoresizingMaskIntoConstraints = false
        ipLabel.isUserInteractionEnabled = true
        ipLabel.tag = 0
        ipLabel.font = UIFont.medium(size: 16)
        ipLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.7)
        ipLabel.textAlignment = .right

        favoriteButton.setImage(UIImage(named: ImagesAsset.IPMenu.save)?.withRenderingMode(.alwaysTemplate)
                                ,for: .normal)
        refreshButton.setImage(UIImage(named: ImagesAsset.IPMenu.refresh)?.withRenderingMode(.alwaysTemplate)
                               , for: .normal)
        closeButton.setImage(UIImage(named: ImagesAsset.IPMenu.close)?.withRenderingMode(.alwaysTemplate)
                             ,for: .normal)
        openButton.setImage(UIImage(named: ImagesAsset.IPMenu.open)?.withRenderingMode(.alwaysTemplate)
                            , for: .normal)

        favoriteButton.imageView?.setImageColor(color: .white)
        refreshButton.imageView?.setImageColor(color: .whiteWithOpacity(opacity: 0.7))
        closeButton.imageView?.setImageColor(color: .whiteWithOpacity(opacity: 0.7))
        openButton.imageView?.setImageColor(color: .whiteWithOpacity(opacity: 0.7))

        favoriteButton.isHidden = true
        refreshButton.isHidden = true
        closeButton.isHidden = true
        openButton.isHidden = false

        stackView.addArrangedSubviews([UIView(), ipLabel, openButton, favoriteButton, refreshButton, closeButton])
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

    private func setFavoriteButtonImage(isFavourited: Bool) -> UIImage? {
        let imageName = isFavourited ? ImagesAsset.IPMenu.isSaved : ImagesAsset.IPMenu.save
        return UIImage(named: imageName)?
            .withRenderingMode(.alwaysTemplate)
    }
}
