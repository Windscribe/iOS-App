//
//  SKPaymentTransaction+Ext.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit
import Swinject

extension SKPaymentTransaction {
    // This is not really a secret.
    private var sharedSecret: String {
        return "952b4412f002315aa50751032fcaab03"
    }
    var signature: String? {
        guard let transactionID = transactionIdentifier,
              let appleData = self.appleData,
              let sessionAuthHash = Assembler.resolve(Preferences.self).userSessionAuth()
        else {
            return nil
        }
        return "\(sharedSecret)\(sessionAuthHash)\(appleData)\(transactionID)".MD5()
    }

    var appleData: String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL, let receiptData = try? Data(contentsOf: receiptURL)
        else {
            return nil
        }
        return receiptData.base64EncodedString()
    }
}
