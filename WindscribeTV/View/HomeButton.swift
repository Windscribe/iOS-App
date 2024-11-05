//
//  HomeButton.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 07/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class HomeButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    func setupButton() {
        // Make the button round
        layer.cornerRadius = frame.size.width / 2
        clipsToBounds = true

        // Set the border color and width
        layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        layer.borderWidth = 2.0

        setTitle(nil, for: .normal)
        isUserInteractionEnabled = true
    }

    // Optionally override layoutSubviews to ensure the button remains round on layout changes
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.width / 2
    }
}

class SettingButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.settingsButton) {
            setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.settingsIconFocused) {
            setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
}

class NotificationButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.notificationsIcon) {
            setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.notificationIconFocused) {
            setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
}

class HelpButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.helpIcon) {
            setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.helpIconFocused) {
            setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
}
