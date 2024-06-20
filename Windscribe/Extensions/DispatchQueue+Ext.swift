//
//  DispatchQueue+Ext.swift
//  Windscribe
//
//  Created by Ginder Singh on 2022-09-15.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
func delay(_ seconds: Double, completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        completion()
    }
}
