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
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
        
        // Set the border color and width
        self.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        self.layer.borderWidth = 2.0
        
        self.setTitle(nil, for: .normal)
        self.isUserInteractionEnabled = true
    }
    
    // Optionally override layoutSubviews to ensure the button remains round on layout changes
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.width / 2
    }
}

class SettingButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.settingsButton) {
            self.setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.settingsIconFocused) {
            self.setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
    
}

class NotificationButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.notificationsIcon) {
            self.setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.notificationIconFocused) {
            self.setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
    
}


class HelpButton: HomeButton {
    override func setupButton() {
        super.setupButton()
        if let backgroundImage = UIImage(named: ImagesAsset.TvAsset.helpIcon) {
            self.setBackgroundImage(backgroundImage, for: .normal)
        }
        if let backgroundImageFocused = UIImage(named: ImagesAsset.TvAsset.helpIconFocused) {
            self.setBackgroundImage(backgroundImageFocused, for: .focused)
        }
    }
    
}

