//
//  ShakeForDataResultViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//
import UIKit

extension ShakeForDataResultViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        highScoreLabel = UILabel()
        highScoreLabel.text = "\(TextsAsset.ShakeForData.highScore) 0"
        highScoreLabel.font = UIFont.text(size: 24)
        highScoreLabel.adjustsFontSizeToFitWidth = true
        highScoreLabel.textColor = UIColor.white
        highScoreLabel.textAlignment = .center
        view.addSubview(highScoreLabel)

        shakeCounterLabel = UILabel()
        shakeCounterLabel.font = UIFont.text(size: 128)
        shakeCounterLabel.adjustsFontSizeToFitWidth = true
        shakeCounterLabel.textColor = UIColor.white
        shakeCounterLabel.textAlignment = .center
        view.addSubview(shakeCounterLabel)

        messageLabel = UILabel()
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.text(size: 24)
        messageLabel.layer.opacity = 0.9
        messageLabel.textColor = UIColor.white
        view.addSubview(messageLabel)

        tryAgainButton = UIButton()
        tryAgainButton.backgroundColor = UIColor.clear
        tryAgainButton.layer.borderWidth = 2
        tryAgainButton.setTitleColor(UIColor.white, for: .normal)
        tryAgainButton.layer.borderColor = UIColor.white.cgColor
        tryAgainButton.layer.cornerRadius = 24
        tryAgainButton.clipsToBounds = true
        tryAgainButton.layer.opacity = 0.7
        tryAgainButton.setTitle(TextsAsset.ShakeForData.tryAgain, for: .normal)
        tryAgainButton.titleLabel?.font = UIFont.text(size: 16)
        tryAgainButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(tryAgainButton)

        viewLeaderboardButton = UIButton(type: .system)
        viewLeaderboardButton.layer.opacity = 0.5
        viewLeaderboardButton.setTitle(TextsAsset.ShakeForData.popupViewLeaderboard, for: .normal)
        viewLeaderboardButton.titleLabel?.font = UIFont.bold(size: 16)
        viewLeaderboardButton.titleLabel?.adjustsFontSizeToFitWidth = true
        viewLeaderboardButton.setTitleColor(UIColor.white, for: .normal)
        view.addSubview(viewLeaderboardButton)

        divider = UIView()
        divider.layer.opacity = 0.15
        divider.backgroundColor = UIColor.white
        view.addSubview(divider)

        quitButton = UIButton(type: .system)
        quitButton.setTitle(TextsAsset.ShakeForData.leave, for: .normal)
        quitButton.setTitleColor(UIColor.white, for: .normal)
        quitButton.titleLabel?.font = UIFont.bold(size: 16)
        quitButton.titleLabel?.adjustsFontSizeToFitWidth = true
        quitButton.layer.opacity = 0.5
        view.addSubview(quitButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        highScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        shakeCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        viewLeaderboardButton.translatesAutoresizingMaskIntoConstraints = false
        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        let isSmallScreen = UIScreen.main.nativeBounds.height <= 1136

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: topSpace),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // highScoreLabel
            highScoreLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: isSmallScreen ? 30 : 125),
            highScoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 38),
            highScoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -38),
            highScoreLabel.heightAnchor.constraint(equalToConstant: 30),

            // shakeCounterLabel
            shakeCounterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shakeCounterLabel.topAnchor.constraint(equalTo: highScoreLabel.bottomAnchor, constant: 24),
            shakeCounterLabel.heightAnchor.constraint(equalToConstant: 120),

            // messageLabel
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: shakeCounterLabel.bottomAnchor, constant: 32),
            messageLabel.heightAnchor.constraint(equalToConstant: 50),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 38),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -38),

            // tryAgainButton
            tryAgainButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            tryAgainButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            tryAgainButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 48),

            // viewLeaderboardButton
            viewLeaderboardButton.topAnchor.constraint(equalTo: tryAgainButton.bottomAnchor, constant: 24),
            viewLeaderboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            viewLeaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            viewLeaderboardButton.heightAnchor.constraint(equalToConstant: 48),

            // divider
            divider.topAnchor.constraint(equalTo: viewLeaderboardButton.bottomAnchor, constant: 24),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 88),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -88),
            divider.heightAnchor.constraint(equalToConstant: 2),

            // quitButton
            quitButton.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 24),
            quitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quitButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}
