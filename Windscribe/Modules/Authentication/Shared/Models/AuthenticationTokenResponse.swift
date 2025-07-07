//
//  AuthenticationTokenResponse.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import UIKit

struct AuthTokenResponse: Decodable {
    let data: AuthTokenData
}

struct AuthTokenData: Decodable {
    let success: Int
    let token: String
    let expiresAt: Int
    let tokenId: String
    let accessLevel: Int

    let algorithm: String
    let version: String
    let requestId: String

    let entropy: Entropy
    let captcha: CaptchaData?

    enum CodingKeys: String, CodingKey {
        case success, token
        case expiresAt = "expires_at"
        case tokenId = "token_id"
        case accessLevel = "access_level"
        case algorithm, version
        case requestId = "request_id"
        case entropy, captcha
    }
}

struct Entropy: Decodable {
    let e: String
    let s: String
}

struct CaptchaData: Decodable {
    let background: String?
    let slider: String?
    let top: Int?
    let asciiArt: String?

    enum CodingKeys: String, CodingKey {
        case background, slider, top
        case asciiArt = "ascii_art"
    }
}

struct CaptchaPopupModel {
    let background: UIImage
    let slider: UIImage
    let top: Int

    init?(from captchaData: CaptchaData) {
        guard let backgroundImageData = captchaData.background,
              let sliderImageData = captchaData.slider,
              let backgroundImage = UIImage.fromBase64(backgroundImageData),
              let sliderImage = UIImage.fromBase64(sliderImageData),
              let topOffset = captchaData.top else {
            return nil
        }

        self.background = backgroundImage
        self.slider = sliderImage
        self.top = topOffset
    }
}
