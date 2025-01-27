//
//  ShakeForDataViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension ShakeForDataViewController {
    func addViews() {
        view.backgroundColor = UIColor.clear

        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        fillView = UIView()
        fillView.layer.cornerRadius = 24
        fillView.backgroundColor = UIColor.backgroundBlue
        view.addSubview(fillView)

        arrowViewTopLeft = UIImageView()
        arrowViewTopLeft.image = UIImage(named: ImagesAsset.shakeForDataArrowTopLeft)
        arrowViewTopLeft.contentMode = .scaleAspectFit
        view.addSubview(arrowViewTopLeft)

        arrowViewTopRight = UIImageView()
        arrowViewTopRight.image = UIImage(named: ImagesAsset.shakeForDataArrowTopRight)
        arrowViewTopRight.contentMode = .scaleAspectFit
        view.addSubview(arrowViewTopRight)

        arrowViewBottomLeft = UIImageView()
        arrowViewBottomLeft.image = UIImage(named: ImagesAsset.shakeForDataArrowBottomLeft)
        arrowViewBottomLeft.contentMode = .scaleAspectFit
        view.addSubview(arrowViewBottomLeft)

        arrowViewBottomRight = UIImageView()
        arrowViewBottomRight.image = UIImage(named: ImagesAsset.shakeForDataArrowBottomRight)
        arrowViewBottomRight.contentMode = .scaleAspectFit
        view.addSubview(arrowViewBottomRight)

        timerIcon = UIImageView()
        timerIcon.image = UIImage(named: ImagesAsset.shakeForDataTimer)
        timerIcon.contentMode = .scaleAspectFit
        view.addSubview(timerIcon)

        timerLabel = UILabel()
        timerLabel.font = UIFont.bold(size: 32)
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.textColor = UIColor.white
        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)

        shakeCounterLabel = UILabel()
        shakeCounterLabel.font = UIFont.text(size: 128)
        shakeCounterLabel.adjustsFontSizeToFitWidth = true
        shakeCounterLabel.textColor = UIColor.white
        shakeCounterLabel.textAlignment = .center
        view.addSubview(shakeCounterLabel)

        shakeInfoLabel = UILabel()
        shakeInfoLabel.adjustsFontSizeToFitWidth = true
        shakeInfoLabel.numberOfLines = 0
        shakeInfoLabel.textAlignment = .center
        shakeInfoLabel.font = UIFont.text(size: 24)
        shakeInfoLabel.layer.opacity = 0.5
        shakeInfoLabel.textColor = UIColor.white
        view.addSubview(shakeInfoLabel)

        quitButton = UIButton(type: .system)
        quitButton.setTitleColor(UIColor.white, for: .normal)
        quitButton.titleLabel?.font = UIFont.bold(size: 16)
        quitButton.titleLabel?.adjustsFontSizeToFitWidth = true
        quitButton.clipsToBounds = true
        quitButton.layer.opacity = 0.5
        view.addSubview(quitButton)
    }

    func addAutoLayoutConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        fillView.translatesAutoresizingMaskIntoConstraints = false
        arrowViewTopLeft.translatesAutoresizingMaskIntoConstraints = false
        arrowViewTopRight.translatesAutoresizingMaskIntoConstraints = false
        arrowViewBottomRight.translatesAutoresizingMaskIntoConstraints = false
        arrowViewBottomLeft.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerIcon.translatesAutoresizingMaskIntoConstraints = false
        shakeCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        shakeInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        quitButton.translatesAutoresizingMaskIntoConstraints = false

        fillViewTopConstraint = fillView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: topSpace)

        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: topSpace),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // fillView
            fillViewTopConstraint,
            fillView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fillView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fillView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // timerIcon
            timerIcon.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            timerIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerIcon.widthAnchor.constraint(equalToConstant: 16),
            timerIcon.heightAnchor.constraint(equalToConstant: 16),

            // timerLabel
            timerLabel.topAnchor.constraint(equalTo: timerIcon.bottomAnchor),
            timerLabel.centerXAnchor.constraint(equalTo: timerIcon.centerXAnchor),
            timerLabel.heightAnchor.constraint(equalToConstant: 42),

            // arrowViewTopLeft
            arrowViewTopLeft.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: UIScreen.hasTopNotch ? 40 : 20),
            arrowViewTopLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            arrowViewTopLeft.widthAnchor.constraint(equalToConstant: 60),
            arrowViewTopLeft.heightAnchor.constraint(equalToConstant: 60),

            // arrowViewTopRight
            arrowViewTopRight.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: UIScreen.hasTopNotch ? 40 : 20),
            arrowViewTopRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            arrowViewTopRight.widthAnchor.constraint(equalToConstant: 60),
            arrowViewTopRight.heightAnchor.constraint(equalToConstant: 60),

            // arrowViewBottomLeft
            arrowViewBottomLeft.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -20),
            arrowViewBottomLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            arrowViewBottomLeft.widthAnchor.constraint(equalToConstant: 60),
            arrowViewBottomLeft.heightAnchor.constraint(equalToConstant: 60),

            // arrowViewBottomRight
            arrowViewBottomRight.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -20),
            arrowViewBottomRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            arrowViewBottomRight.widthAnchor.constraint(equalToConstant: 60),
            arrowViewBottomRight.heightAnchor.constraint(equalToConstant: 60),

            // shakeCounterLabel
            shakeCounterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shakeCounterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            shakeCounterLabel.heightAnchor.constraint(equalToConstant: 120),

            // shakeInfoLabel
            shakeInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shakeInfoLabel.topAnchor.constraint(equalTo: shakeCounterLabel.bottomAnchor, constant: 12),
            shakeInfoLabel.heightAnchor.constraint(equalToConstant: 30),

            // quitButton
            quitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),
            quitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quitButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}
