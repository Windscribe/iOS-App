//
//  ReferAndShareManagerV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-03-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol ReferAndShareManagerV2 {
    func checkAndShowDialogFirstTime(completion: @escaping () -> Void)
    func setShowedShareDialog(showed: Bool)
}
