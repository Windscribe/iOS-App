//
//  APIMessage+Test.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-12-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

extension APIMessage {
    static func mock(message: String = "", success: Bool = false) -> APIMessage {
        // Create mock JSON data matching APIMessage's expected structure
        let jsonString = """
        {
            "data": {
                "message": "\(message)",
                "success": \(success ? 1 : 0)
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(APIMessage.self, from: jsonData)
    }
}
