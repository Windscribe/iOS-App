//
//  Language.swift
//  Windscribe
//
//  Created by Thomas on 20/04/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum Languages: String, CaseIterable {
    case arabic = "ar"
    case bengali = "bn"
    case german = "de-DE"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case hindi = "hi"
    case indonesian = "id-ID"
    case italian = "it-IT"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case polish = "pl"
    case portugal = "pt-PT"
    case russian = "ru"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"
    case chineseSimplified = "zh-Hans"
    case chineseHK = "zh-Hant-TW"

    var name: String {
        switch self {
        case .arabic:
            return "العربية"
        case .bengali:
            return "বাংলা"
        case .german:
            return "Deutsch"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .hindi:
            return "हिंदी"
        case .indonesian:
            return "Indonesian"
        case .italian:
            return "Italiano"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .polish:
            return "Polski"
        case .portugal:
            return "Português (Brasil)"
        case .russian:
            return "Pусский"
        case .turkish:
            return "Türkçe"
        case .ukrainian:
            return "Українська"
        case .vietnamese:
            return "Tiếng Việt"
        case .chineseSimplified:
            return "中文"
        case .chineseHK:
            return "中文(台灣)"
        }
    }

    init?(name: String) {
        if name == Languages.arabic.name { self = .arabic } else if name == Languages.bengali.name { self = .bengali } else if name == Languages.german.name { self = .german } else if name == Languages.english.name { self = .english } else if name == Languages.spanish.name { self = .spanish } else if name == Languages.french.name { self = .french } else if name == Languages.hindi.name { self = .hindi } else if name == Languages.indonesian.name { self = .indonesian } else if name == Languages.italian.name { self = .italian } else if name == Languages.japanese.name { self = .japanese } else if name == Languages.korean.name { self = .korean } else if name == Languages.polish.name { self = .polish } else if name == Languages.portugal.name { self = .portugal } else if name == Languages.russian.name { self = .russian } else if name == Languages.ukrainian.name { self = .ukrainian } else if name == Languages.vietnamese.name { self = .vietnamese } else if name == Languages.chineseSimplified.name { self = .chineseSimplified } else if name == Languages.chineseHK.name { self = .chineseHK } else { return nil }
    }
}
