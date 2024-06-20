//
//	LanguageDataCell.swift
//	Windscribe
//
//	Created by Thomas on 25/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import Swinject

struct LanguageDataCell {
    let language: Languages

    func isShowGreenMarkCheck() -> Bool {
        return language.rawValue == Assembler.resolve(LanguageManagerV2.self).getCurrentLanguage().rawValue
    }
}
