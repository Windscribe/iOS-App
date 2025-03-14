//
//  HTMLParsing.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

protocol HTMLParsing {
    func parse(description: String) -> ParsedContent
}
