//
//  LanguageManagerV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LanguageManagerV2 {
    var activelanguage: BehaviorSubject<Languages> { get }
    func setAppLanguage()
    func setLanguage(language: Languages)
    func getCurrentLanguage() -> Languages
}
