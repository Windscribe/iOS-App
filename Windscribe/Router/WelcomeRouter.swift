//
//  WelcomeRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import SwiftUI

class WelcomeRouter: BaseRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.home:
            goToHome()
        default: ()
        }
    }
}
